import tkinter as tk
from tkinter import ttk
import os

from config import VIEW_COUNT

version = '0.2.0'

# === Paths ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, 'data')

PATH_NAMES = os.path.join(DATA_DIR, 'names.txt')
PATH_NAME_URL = os.path.join(DATA_DIR, 'name_url.txt')

os.makedirs(DATA_DIR, exist_ok=True)


# === GUI ===
class ControllerGUI(tk.Tk):
    def __init__(self):
        super().__init__()

        self.title(f'Easy MultiView Controller v{version}')
        self.resizable(False, False)

        ROW_HEIGHT = 32
        HEADER_ROWS = 1
        FOOTER_ROWS = 2
        MARGIN = -8

        total_rows = HEADER_ROWS + VIEW_COUNT + FOOTER_ROWS
        height = total_rows * ROW_HEIGHT + MARGIN
        width = 490

        self.geometry(f'{width}x{height}')

        self.players = []
        self.focus_var = tk.IntVar(value=-1)

        self.name_url = {}
        self._load_name_url()
        self._prepare_files()
        self._build_ui()
        self._load_state()


    def _prepare_files(self):
        if not os.path.exists(PATH_NAMES):
            with open(PATH_NAMES, 'w', encoding='utf-8') as f:
                f.write('\n'.join([''] * VIEW_COUNT) + '\n-1')

    def _load_name_url(self):
        self.name_url = {}
        if not os.path.exists(PATH_NAME_URL):
            return

        with open(PATH_NAME_URL, encoding='utf-8') as f:
            for line in f:
                if ' : ' in line:
                    name, url = line.strip().split(' : ', 1)
                    self.name_url[name] = url


    def _build_ui(self):
        pad = {'padx': 5, 'pady': 3}

        header = ['Player', 'Name', 'Volume (dB)', '', '', 'Focus']
        for c, h in enumerate(header):
            ttk.Label(self, text=h).grid(row=0, column=c, **pad)

        for i in range(VIEW_COUNT):
            ttk.Label(self, text=f'{i+1}').grid(row=i+1, column=0, **pad)

            name_var = tk.StringVar()
            url_var = tk.StringVar()
            db_var = tk.IntVar(value=0)

            combo = ttk.Combobox(
                self,
                values=list(self.name_url.keys()),
                textvariable=name_var,
                state='readonly',
                width=16
            )
            combo.grid(row=i+1, column=1, **pad)
            combo.bind('<<ComboboxSelected>>',
                       lambda e, idx=i: self._on_name_changed(idx))

            slider = ttk.Scale(
                self,
                from_=-40,
                to=20,
                orient='horizontal',
                variable=db_var,
                command=lambda v, idx=i: self._update_db_label(idx)
            )
            slider.grid(row=i+1, column=2, sticky='ew', **pad)

            db_label = ttk.Label(self, text='0 dB', width=6)
            db_label.grid(row=i+1, column=3, **pad)

            ttk.Button(
                self,
                text='Clear',
                width=6,
                command=lambda idx=i: self.clear_player(idx)
            ).grid(row=i+1, column=4, **pad)

            ttk.Radiobutton(
                self,
                variable=self.focus_var,
                value=i,
                command=self.save_state
            ).grid(row=i+1, column=5, **pad)

            self.players.append({
                'name': name_var,
                'url': url_var,
                'db': db_var,
                'db_label': db_label,
                'combo': combo
            })

        ttk.Radiobutton(
            self,
            text='No Focus',
            variable=self.focus_var,
            value=-1,
            command=self.save_state
        ).grid(row=VIEW_COUNT+1, column=5)

        ttk.Button(self, text='Reload', command=self.reload_names)\
            .grid(row=VIEW_COUNT+2, column=1, pady=8)

        ttk.Button(self, text='Save', command=self.save_state)\
            .grid(row=VIEW_COUNT+2, column=2, pady=8)


        ttk.Button(self, text='Clear All', command=self.clear_all)\
            .grid(row=VIEW_COUNT+2, column=4, pady=8)


    def _on_name_changed(self, idx):
        name = self.players[idx]['name'].get()
        self.players[idx]['url'].set(self.name_url.get(name, ''))

    def _update_db_label(self, idx):
        db = int(self.players[idx]['db'].get())
        self.players[idx]['db_label'].config(text=f'{db} dB')

    def clear_player(self, idx):
        self.players[idx]['name'].set('')
        self.players[idx]['url'].set('')
        self.players[idx]['db'].set(0)
        self.players[idx]['db_label'].config(text='0 dB')
        self.save_state()

    def clear_all(self):
        for p in self.players:
            p['name'].set('')
            p['url'].set('')
            p['db'].set(0)
            p['db_label'].config(text='0 dB')
        self.focus_var.set(-1)
        self.save_state()


    def save_state(self):
        lines = []
        for p in self.players:
            url = p['url'].get()
            db = p['db'].get()
            lines.append(f'{url} | {int(db)}' if url else '')

        lines.append(str(self.focus_var.get()))

        with open(PATH_NAMES, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

    def _load_state(self):
        if not os.path.exists(PATH_NAMES):
            return

        with open(PATH_NAMES, encoding='utf-8') as f:
            lines = f.read().splitlines()

        for i in range(min(VIEW_COUNT, len(lines))):
            if '|' in lines[i]:
                url, db = lines[i].split('|', 1)
                url = url.strip()
                db = int(db.strip())
            else:
                url = lines[i].strip()
                db = 0

            for name, u in self.name_url.items():
                if u == url:
                    self.players[i]['name'].set(name)
                    self.players[i]['url'].set(url)
                    break

            self.players[i]['db'].set(db)
            self.players[i]['db_label'].config(text=f'{db} dB')

        try:
            self.focus_var.set(int(lines[-1]))
        except Exception:
            self.focus_var.set(-1)

    def reload_names(self):
        self._load_name_url()
        for p in self.players:
            p['combo']['values'] = list(self.name_url.keys())
            p['name'].set('')
            p['url'].set('')


# === Loop ===
if __name__ == '__main__':
    ControllerGUI().mainloop()
    