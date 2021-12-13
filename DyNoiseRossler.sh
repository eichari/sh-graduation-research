#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/10/30
# 
# ダイナミカルノイズがある場合のレスラー方程式を
# LIFへ入力した場合にノイズを取り除くことができるか

# (Dynamical Noise)rossler->LIF->ISI

LIFtheta=20
#time=10
time=250
dt=0.001
transient=1000
k=0.0
adjust=40
seed=10
epsilon=0

for i in 0 0.01 0.1 1 5 10 
do
  epsilon=`echo $i`
  echo "///// epsilon= ${epsilon} /////"
  dir="../2020-10/1030/time250syusei/epsilon_${epsilon}/"
  mkdir ../2020-10/1030/time250syusei/epsilon_${epsilon}


  echo "/////  ${dir}  /////"
  echo "/////  LIFへ入力  /////"
  # rossler x(t) の時系列の生成（長さn=200）
  ./dyrossler -time ${time} -dt ${dt} -transient ${transient} -xyz 4 -sampling 1 -adjust ${adjust} -epsilon ${epsilon} -seed ${seed} > ${dir}dyrossler.dat
  ./dyrossler -time ${time} -dt ${dt} -transient ${transient} -xyz 3 -sampling 1 -adjust 0 -epsilon ${epsilon} -seed ${seed} > ${dir}dyrossler_tx.dat #入力時系列
  ./dyrossler -time ${time} -dt ${dt} -transient ${transient} -xyz 6 -sampling 1 -adjust 0 -epsilon ${epsilon} -seed ${seed} > ${dir}dyrossler_xyz.dat #入力時系列

  # ノイズを加える
  #./noise -p ${p} -seed ${seed} < ${dir}dyrossler.dat > ${dir}dyrossler_noise.dat #ノイズを加えた入力時系列
  #./match -dt ${dt} < ${dir}dyrossler_noise.dat > ${dir}dyrossler_noise_tx.dat #   S(t) = x(t) + w_p(t)

  # LIFへ入力
  ./lif -time ${time} -dt ${dt} -transient 0 -k ${k} -Theta ${LIFtheta} -v -1 < ${dir}dyrossler.dat > ${dir}dyrossler_lif.dat #発火時刻時系列 T(i)
  ./lif -time ${time} -dt ${dt} -transient 0 -k ${k} -Theta ${LIFtheta} -v 1 < ${dir}dyrossler.dat > ${dir}dyrossler_lif_vt.dat #膜電位時系列 V(t)
  ./lif -time ${time} -dt ${dt} -transient 0 -k ${k} -Theta ${LIFtheta} -v 0 < ${dir}dyrossler.dat > ${dir}dyrossler_lif_v.dat #膜電位時系列 V
  ./lif -time ${time} -dt ${dt} -transient 0 -k ${k} -Theta ${LIFtheta} -v 2 < ${dir}dyrossler.dat > ${dir}dyrossler_lif_fire.dat #膜電位時系列 V

  # ISIを求める
  ./isi < ${dir}dyrossler_lif.dat > ${dir}dyrossler_isi.dat #発火間隔時系列 ISI(i)
  ./isi < ${dir}dyrossler_lif_v.dat > ${dir}dyrossler_lif_vt_isi.dat #膜電位の差分時系列 V()

  # dyrossler_tx と rossler_isi の重ね書き 一致すればノイズは除去できないことがわかる
  # dyrossler
  ./standardize2 < ${dir}dyrossler_tx.dat > ${dir}dyrossler_tx_sta.dat
  # isi
  ./standardize < ${dir}dyrossler_isi.dat > ${dir}dyrossler_isi_sta.dat
  # ISIの時系列長を参照
  isin=`head -n 1 ${dir}dyrossler_isi.dat | awk -F' ' '{print $3}'`
  echo "isin= ${isin}"
  isimatch=`echo "${time} / ${isin}" | bc -l`
  match=`echo 0${isimatch}`
  ./standardize < ${dir}dyrossler_isi.dat > ${dir}dyrossler_isi_sta.dat
  ./match -dt ${match} < ${dir}dyrossler_isi_sta.dat > ${dir}dyrossler_isi_sta_m.dat 
  ./minus2 < ${dir}dyrossler_isi_sta_m.dat > ${dir}dyrossler_isi_sta_m_mi.dat

  # dyrossler_tx.dat 入力時系列 [-10:15]
  # dyrossler_noise_tx.dat ノイズを加えた入力時系列 [-100:150]
  # dyrossler_lif.dat 発火時刻時系列 
  # dyrossler_isi.dat 発火間隔時系列
  # dyrossler_lif_vt.dat 膜電位時系列 []
  # dyrossler_lif_vt_isi.dat 各時刻ごとの膜電位の差の時系列

done