#!/usr/bin/env python3
"""Summarize logged in-game controller observations; do not infer missing cases."""
from pathlib import Path
import argparse,hashlib,json,math,re
p=argparse.ArgumentParser();p.add_argument('log',type=Path);p.add_argument('output',type=Path);p.add_argument('--controller',type=Path,default=Path('runtime/candidates/native-rider-controls/autorun.as'));p.add_argument('--diagnostic',type=Path);a=p.parse_args();blob=a.log.read_bytes();text=blob.decode(errors='replace')
pattern=r'DRIVE (\w+) pos=([-\d.,e+]+) up=([-\d.e+]+) heading=([-\d.,e+]+) mounted=(true|false) speed=([-\d.e+]+) pad=([-\d,]+)'
rows=[]
for match in re.finditer(pattern,text):
 label,pos,up,heading,mounted,speed,pad=match.groups();rows.append(dict(label=label,position=list(map(float,pos.split(','))),up=float(up),heading=list(map(float,heading.split(','))),mounted=mounted=='true',commanded_speed=float(speed),pad=list(map(int,pad.split(',')))))
index={x['label']:x for x in rows}
def distance(x,y):return math.dist(x['position'],y['position'])
def flatdistance(x,y):return math.hypot(x['position'][0]-y['position'][0],x['position'][2]-y['position'][2])
def angle(x):return math.atan2(*x['heading'])
def anglechange(x,y):return (angle(y)-angle(x)+math.pi)%(2*math.pi)-math.pi
checks={}
if {'beforeA','afterA'}<=index.keys():checks['native_ground_mount']=not index['beforeA']['mounted'] and index['afterA']['mounted']
if {'afterA','end0'}<=index.keys():checks['forward_moves']=flatdistance(index['afterA'],index['end0'])>3
if {'end0','end1'}<=index.keys():checks['right_changes_heading']=abs(anglechange(index['end0'],index['end1']))>.2
if 'end2'in index:checks['neutral_brakes_command_to_zero']=abs(index['end2']['commanded_speed'])<.01
if {'end2','end3'}<=index.keys():
 before=index['end2'];after=index['end3'];delta=[after['position'][j]-before['position'][j]for j in [0,2]]
 checks['reverse_moves_backwards']=sum(x*y for x,y in zip(delta,before['heading']))<-.5
if {'p4f30','end4'}<=index.keys():checks['left_changes_heading']=abs(anglechange(index['p4f30'],index['end4']))>.2
if 'afterB'in index:checks['native_B_dismount']=not index['afterB']['mounted']
if 'unmountedEnd'in index:checks['unmounted_pad_does_not_engage_controller']=not index['unmountedEnd']['mounted'] and index['unmountedEnd']['commanded_speed']==0
if {'parkStart','parkEnd'}<=index.keys():checks['parking_holds_on_sampled_slope']=flatdistance(index['parkStart'],index['parkEnd'])<.15
if 'remounted'in index:checks['recall_allows_native_remount']=index['remounted']['mounted']
if 'RECALL same='in text:checks['recall_reuses_same_actor']='RECALL same=true'in text
if 'KART spawn queued'in text:checks['spawn_shortcut_queued_in_normal_loop']=True
moving=[x for x in rows if re.fullmatch(r'p\d+f\d+|end\d+',x['label'])]
if moving:checks['sampled_up_axis_above_0_8']=min(x['up']for x in moving)>.8;checks['mounted_during_all_drive_samples']=all(x['mounted']for x in moving)
result=dict(status='Completed in-game observations'if 'DRIVE finished'in text else'Incomplete; inspect log',log=str(a.log),log_sha256=hashlib.sha256(blob).hexdigest(),controller=str(a.controller),controller_sha256=hashlib.sha256(a.controller.read_bytes()).hexdigest(),test_builder='scripts/build_native_controller_test.py',completed='DRIVE finished'in text,checks=checks,all_available_checks_pass=bool(checks)and all(checks.values()),samples=rows,limits=['Pad values are read from the same runtime bridge used by the resident controller.','One terrain route near Lookout Landing; not general terrain/hardware coverage.','Up-axis values are periodic samples, not every rendered frame.','Pose selection and visual fit are recorded separately; movement samples alone do not establish animation quality.'])
if {'afterA','end0'}<=index.keys():result['forward_distance']=distance(index['afterA'],index['end0'])
if a.diagnostic:result['diagnostic_script']={'path':str(a.diagnostic),'sha256':hashlib.sha256(a.diagnostic.read_bytes()).hexdigest()}
if {'afterB','unmountedEnd'}<=index.keys():result['post_exit_horizontal_displacement']=flatdistance(index['afterB'],index['unmountedEnd'])
if {'exit0','afterB'}<=index.keys():result['dismount_horizontal_displacement']=flatdistance(index['exit0'],index['afterB'])
if {'parkStart','parkEnd'}<=index.keys():result['parking_hold_horizontal_drift']=flatdistance(index['parkStart'],index['parkEnd'])
if moving:result['minimum_sampled_up']=min(x['up']for x in moving)
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items()if k not in ['samples','limits']},indent=2))
