"""Tests for server/dcc_companion.py (web map + Discord feed).

    python tests/test_companion.py
"""
import json
import os
import sys
import tempfile
import threading
import unittest
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "server"))
import dcc_companion as C  # noqa: E402


class FakeDiscord:
    """A local webhook that records what was posted."""

    def __init__(self, fail=False):
        self.posts, self.fail = [], fail
        outer = self

        class H(BaseHTTPRequestHandler):
            def do_POST(self):
                body = self.rfile.read(int(self.headers["Content-Length"]))
                if outer.fail:
                    self.send_response(429)
                    self.end_headers()
                    return
                outer.posts.append(json.loads(body))
                self.send_response(204)
                self.end_headers()

            def log_message(self, *a):
                pass
        self.srv = ThreadingHTTPServer(("127.0.0.1", 0), H)
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()
        self.url = f"http://127.0.0.1:{self.srv.server_address[1]}/hook"

    def close(self):
        self.srv.shutdown()


def write_feed(folder, events, mode="a"):
    with open(os.path.join(folder, "feed.jsonl"), mode, encoding="utf-8") as f:
        for ev in events:
            f.write(json.dumps(ev) + "\n")


class CompanionTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.hook = FakeDiscord()
        self.cfg = C.load_config(["--dcc", self.dir, "--webhook", self.hook.url, "--config", "none"])

    def tearDown(self):
        self.hook.close()

    def test_posts_each_event_once(self):
        write_feed(self.dir, [
            {"seq": 1, "warId": "W1", "kind": "capture", "text": "BLUE captured Gali from RED"},
            {"seq": 2, "warId": "W1", "kind": "ewr_destroyed", "text": "RED early-warning radar at Beslan destroyed"},
        ])
        feed = C.Feed(self.cfg)
        self.assertEqual(feed.run_once(), 2)
        self.assertEqual(len(self.hook.posts), 1)                 # grouped into one message
        self.assertIn("🚩 BLUE captured Gali", self.hook.posts[0]["content"])
        self.assertEqual(C.Feed(self.cfg).run_once(), 0)          # restart: nothing again
        write_feed(self.dir, [{"seq": 3, "warId": "W1", "kind": "victory", "text": "BLUE wins"}])
        self.assertEqual(C.Feed(self.cfg).run_once(), 1)
        self.assertEqual(len(self.hook.posts), 2)
        self.assertIn("🏆 BLUE wins", self.hook.posts[1]["content"])

    def test_report_in_code_block_and_new_war_numbering(self):
        write_feed(self.dir, [{"seq": 9, "warId": "W1", "kind": "report", "text": "=== WAR REPORT ==="},
                              {"seq": 1, "warId": "W2", "kind": "capture", "text": "first capture of war 2"}])
        C.Feed(self.cfg).run_once()
        self.assertTrue(self.hook.posts[0]["content"].startswith("📜 **War report**\n```"))
        self.assertIn("first capture of war 2", self.hook.posts[1]["content"])

    def test_discord_down_keeps_events(self):
        self.hook.fail = True
        write_feed(self.dir, [{"seq": 1, "warId": "W1", "kind": "capture", "text": "x"}])
        self.assertEqual(C.Feed(self.cfg).run_once(), 0)
        self.hook.fail = False
        self.assertEqual(C.Feed(self.cfg).run_once(), 1)
        self.assertEqual(len(self.hook.posts), 1)

    def test_half_written_line_waits(self):
        with open(os.path.join(self.dir, "feed.jsonl"), "w", encoding="utf-8") as f:
            f.write(json.dumps({"seq": 1, "warId": "W1", "kind": "capture", "text": "done"}) + "\n")
            f.write('{"seq": 2, "warId": "W1", "kind": "cap')
        self.assertEqual(C.Feed(self.cfg).run_once(), 1)
        with open(os.path.join(self.dir, "feed.jsonl"), "a", encoding="utf-8") as f:
            f.write('ture", "text": "late"}\n')
        self.assertEqual(C.Feed(self.cfg).run_once(), 1)
        self.assertIn("late", self.hook.posts[-1]["content"])

    def test_long_bursts_are_split(self):
        write_feed(self.dir, [{"seq": i, "warId": "W1", "kind": "capture", "text": "x" * 150} for i in range(1, 40)])
        C.Feed(self.cfg).run_once()
        self.assertGreater(len(self.hook.posts), 1)
        self.assertTrue(all(len(p["content"]) <= 2000 for p in self.hook.posts))

    def test_web_map_serves_page_and_status(self):
        with open(os.path.join(self.dir, "public.json"), "w", encoding="utf-8") as f:
            json.dump({"map": "Caucasus", "nodes": [], "bases": {"blue": 20, "red": 19}}, f)
        srv = ThreadingHTTPServer(("127.0.0.1", 0), C.make_handler(self.cfg))
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        base = f"http://127.0.0.1:{srv.server_address[1]}"
        page = urllib.request.urlopen(base + "/").read().decode()
        self.assertIn("leaflet@1.9.4", page)
        data = json.loads(urllib.request.urlopen(base + "/public.json?1").read())
        self.assertEqual(data["bases"]["blue"], 20)
        srv.shutdown()

    def test_static_export(self):
        with open(os.path.join(self.dir, "public.json"), "w") as f:
            f.write("{}")
        out = os.path.join(self.dir, "site")
        C.write_static(self.cfg, out)
        self.assertTrue(os.path.exists(os.path.join(out, "index.html")))
        self.assertTrue(os.path.exists(os.path.join(out, "public.json")))


if __name__ == "__main__":
    unittest.main(verbosity=1)
