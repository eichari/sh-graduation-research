#!/usr/bin/zsh
# /mnt/c/uno/mingw/genjo_report/rossler/cyclen.sh
# 周期応答を示すレスラー方程式の第1変数をLIFに入力したときに出力される発火時刻と発火時間間隔を求める
dt=0.01
time=1000
./rossler -a 0.2 -b 1.6 -c 5.7 -time ${time} -transient 5000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 5 -adjust 40 > cycle_1_x.dat
./rossler -a 0.2 -b 1.0 -c 5.7 -time ${time} -transient 5000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 5 -adjust 40 > cycle_2_x.dat
./rossler -a 0.2 -b 0.8 -c 5.7 -time ${time} -transient 5000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 5 -adjust 40 > cycle_4_x.dat
./rossler -a 0.2 -b 0.72 -c 5.7 -time ${time} -transient 5000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 5 -adjust 40 > cycle_8_x.dat
./rossler -a 0.2 -b 0.2 -c 5.7 -time ${time} -transient 5000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 5 -adjust 40 > cycle_chaos_x.dat
for i in 1 2 4 8
do
  echo ${i}
  ./lif -transient 0 -time ${time} -dt ${dt} -k 0 -Theta 20 -v 3 < cycle_${i}_x.dat > cycle_${i}_x_lif.dat
  ./isi -spike 20 < cycle_${i}_x_lif.dat > cycle_${i}_x_lif_isi.dat
  ./reconstruct -m 3 -tau 1 < cycle_${i}_x_lif_isi.dat > cycle_${i}_x_lif_isi_re.dat
done
./lif -transient 0 -time ${time} -dt ${dt} -k 0 -Theta 20 -v 3 < cycle_chaos_x.dat > cycle_chaos_x_lif.dat
./isi -spike 20 < cycle_chaos_x_lif.dat > cycle_chaos_x_lif_isi.dat
./reconstruct -m 3 -tau 1 < cycle_chaos_x_lif_isi.dat > cycle_chaos_x_lif_isi_re.dat
