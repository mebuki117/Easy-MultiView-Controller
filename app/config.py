import configparser
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INI_PATH = os.path.join(BASE_DIR, 'config.ini')

_config = configparser.ConfigParser()
_config.read(INI_PATH, encoding='utf-8')


# === General ===
VIEW_COUNT = _config.getint('GENERAL', 'VIEW_COUNT', fallback=6)