from datetime import datetime


class Logger:
    def __init__(self, context: str):
        self.context = context

    def _log(self, level: str, message: str):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] [{self.context}] {message}")

    def info(self, message: str):
        self._log("INFO", message)

    def error(self, message: str):
        self._log("ERROR", message)

    def warning(self, message: str):
        self._log("WARNING", message)
