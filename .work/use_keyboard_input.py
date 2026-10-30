# Test-only: point Ryujinx Player1 at the keyboard (no controller attached). Restore from .work/Config.json.ps4-backup.
import json,pathlib
p=pathlib.Path.home()/'Library/Application Support/Ryujinx/Config.json'
c=json.load(open(p))
c['input_config']=[{"left_joycon_stick":{"stick_up":"W","stick_down":"S","stick_left":"A","stick_right":"D","stick_button":"F"},
"right_joycon_stick":{"stick_up":"I","stick_down":"K","stick_left":"J","stick_right":"L","stick_button":"H"},
"left_joycon":{"button_minus":"Minus","button_l":"E","button_zl":"Q","button_sl":"Unbound","button_sr":"Unbound","dpad_up":"Up","dpad_down":"Down","dpad_left":"Left","dpad_right":"Right"},
"right_joycon":{"button_plus":"Plus","button_r":"U","button_zr":"O","button_sl":"Unbound","button_sr":"Unbound","button_x":"C","button_b":"N","button_y":"X","button_a":"Z"},
"version":1,"backend":"WindowKeyboard","id":"0","name":"All keyboards","controller_type":"ProController","player_index":"Player1"}]
json.dump(c,open(p,'w'),indent=2)
