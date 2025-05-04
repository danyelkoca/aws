## Create bucket
```sh
aws s3 mb s3://rollsbucketroyse
```

## Create folder
```sh
aws s3api put-object --bucket rollsbucketroyse --key hello/ --no-cli-auto-prompt
```

## Create many folders
```sh
aws s3api put-object --bucket rollsbucketroyse --key "a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z/A/B/C/D/E/F/G/H/I/J/K/L/M/N/O/P/Q/R/S/T/U/V/W/X/Y/Z/1/2/3/4/5/6/7/8/9/0/a1/b2/c3/d4/e5/f6/g7/h8/i9/j0/k1/l2/m3/n4/o5/p6/q7/r8/s9/t0/u1/v2/w3/x4/y5/z6/A7/B8/C9/D0/E1/F2/G3/H4/I5/J6/K7/L8/M9/N0/O1/P2/Q3/R4/S5/T6/U7/V8/W9/X0/Y1/Z2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0" --no-cli-auto-prompt
```

## Check objects
```sh
aws s3api list-objects --bucket rollsbucketroyse
```

