from typing import List

from kittens.tui.handler import result_handler
from kitty.boss import Boss


TITLE = "Screen Snapshot"


def main(args: List[str]):
    pass


@result_handler(no_ui=True)
def handle_result(args: List[str], _: str, target_window_id: int, boss: Boss) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return

    text = w.as_text(as_ansi=True, add_history=True, add_wrap_markers=True)
    data = w.pipe_data(text, has_wrap_markers=True)
    cursor_on_screen = w.screen.scrolled_by < w.screen.lines - w.screen.cursor.y
    boss.display_scrollback(w, data["text"], data["input_line_number"], title=TITLE, report_cursor=cursor_on_screen)
