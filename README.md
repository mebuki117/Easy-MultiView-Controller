## 説明
OBSでYouTube/Twitch配信をミラーするためのコントローラー。

## 動作環境
[Python](https://www.python.org/)をインストール。  
バージョンは新しければ何でもいいと思うが、開発環境はv3.12.10。

## 事前設定
1. OBSに、シーンとブラウザソースを追加する（[OBSの設定](#obs)を参照）
2. OBSのスクリプトに、`obs_controller.lua`を追加する
3. `data\name_url.txt`の各行に、`[Name] : [YouTube or Twitch URL]`を追加する

## 使い方
1. `main controller.pyw`を起動
2. 表示するユーザーを切り替える
3. `Save`をクリック

## 機能
| 機能 | 説明 | 備考 |
|----|----|----|
| Save | 保存 | ユーザーの切り替えと音量のみ、Saveを押した際に更新される |
| Volume (dB) | 音量 | -40dBはミュートと同等。一応滑らかに切り替わる |
| Clear | ユーザーの表示をクリア |  |
| All Clear | 全てのユーザーの表示をクリア |  |
| Reload | `name_url.txt`を再読み込み |  |
| Focus | 指定のユーザーをフォーカスする | フォーカスのシーンに切り替えて、`FOCUS_BROSER_FMT 1`に表示する |

## 設定
### コントローラー
`config.ini`から設定を変更できる。

#### GENERAL
| 設定 | 説明 | 備考 |
|----|----|----|
| VIEW_COUNT | ミラーの最大表示数 | 表示数を多くしてもウインドウが縦長になるだけで、スライダーは追加されない |

#### OBS
| 設定 | 説明 | 備考 |
|----|----|----|
| NORMAL_BROWSER_FMT | 通常のブラウザーソースフォーマット | 通常のシーンに追加する。<br>フォーマットの末尾に` N`が付く。<br>例：`Normal_Player 1`, `Normal_Player 2` |
| FOCUS_BROSER_FMT | フォーカスのブラウザーソースフォーマット | フォーカスのシーンに追加する。<br>フォーマットの末尾に` N`が付く。<br>例：`Focus_Player 1`, `Focus_Player 2` |
| NAME_FMT | 名前用のテキストソースフォーマット | 自動的に名前を切り替えるためのもの。両方のシーンで共通。<br>フォーマットの末尾に` N`が付く。<br>例：`Name 1`, `Name 2`  |
| NORMAL_SCENE | 通常のシーン |  |
| FOCUS_SCENE | フォーカスのシーン |  |
| AUTONAME | 自動的な名前の切り替え | boolean (`true`/`false`) |

### ユーザー
`name_url.txt`の各行に、`[Name] : [YouTube or Twitch URL]`を追加する（例：`mebuki117 : https://www.twitch.tv/mebuki117`）。  
`[Name]`と`[YouTube or Twitch URL]`の間には、`[ : ]`（半角スペースと半角コロン）が必要。