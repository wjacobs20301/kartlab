#!/usr/bin/env python3
"""Summarize logged game observations without treating host stubs as physics."""
import argparse,json,math,re
from pathlib import Path


def summarize(log):
    lines=Path(log).read_text(errors='replace').splitlines();cases={}
    vec=r'([-+\d.e]+),([-+\d.e]+),([-+\d.e]+)'
    for line in lines:
        m=re.search(r'PHYS result mode=(\d+) start='+vec+r' end='+vec,line)
        if m:
            mode=int(m[1]);v=list(map(float,m.groups()[1:]));start,end=v[:3],v[3:]
            delta=[b-a for a,b in zip(start,end)]
            cases.setdefault(mode,{}).update(start=start,end=end,displacement=delta,
                                            horizontal_displacement=math.hypot(delta[0],delta[2]))
        m=re.search(r'PHYS metrics mode=(\d+) ranges='+vec+r' minUp=([-+\d.e]+) maxSpeed=([-+\d.e]+) finalVel='+vec,line)
        if m:
            values=list(map(float,m.groups()[1:]))
            cases.setdefault(int(m[1]),{}).update(position_ranges=values[:3],minimum_up_y=values[3],
                                                peak_horizontal_speed=values[4],final_velocity=values[5:])
    return dict(log=str(log),completed=any('PHYS all cases finished'in l for l in lines),
                cases=cases,observations=[l for l in lines if 'PHYS 'in l],
                limits=['Four separate actors at different road positions','No seated rider or steering validation from linear movement alone',
                        'Sampled transforms/velocities; visual observations and hardware tests remain separate'])


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('log');p.add_argument('output');a=p.parse_args()
    result=summarize(a.log);Path(a.output).write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:result[k]for k in ('completed','cases')},indent=2))
