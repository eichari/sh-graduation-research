#!/usr/bin/zsh
# leakisin.sh
# 作成者: Ei Miura
# 最終更新日: 2020/11/25
# LIFモデルの漏れkを細かく変化させて
# ISIのデータ数がどの程度変化するか確認する

# (rossler->noise->lif->isi->再構成->RP)*n→RPs→RPth->weight->dijkstra->多次元尺度法 

echo "///// leakisin.sh /////"


# ///// パラメータ /////
# rossler
time=250
dt=0.001
transient=1000
#adjust=40
adjust=0
sampling=20
# noise
p=-15
seed=11
# LIF
k=0.0
Theta=20
# RP
theta=0.1 # RPの閾値θ

echo "///// parameter /////"
echo "time= ${time}, dt=${dt}, transient=${transient}, adjust=${adjust}"
echo "p=${p}, seed=${seed}, k=${k}, Theta=${Theta}, theta=${theta}"
echo "/////////////////////"



# ディレクトリ
dir1="../2020-11/1125/"
echo "///// ${dir1} /////"
dir2="${dir1}leakisin/"
mkdir ${dir2}
rm ${dir2}number_of_isi.dat
touch ${dir2}number_of_isi.dat


bias=50.35 # k=1.0 前後で発火数 500となるように 

# 共通入力
echo "///// 共通入力 /////"
# x(t) 共通入力                                                                  /////////////////
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient ${transient} -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust ${adjust} -sampling 1 > ${dir2}rossler.dat

# バイアス項を加える
./bias -b ${bias} < ${dir2}rossler.dat > ${dir2}rossler_bias.dat


echo "///// change value of k /////"
# LIFモデルの漏れkを変える
k=0.0000
for k in `./num -start 0.000 -dt 0.001 -time 2.4001`
do  
  # ノイズを加える
  #echo -n "noise  "
  #./noise -p ${p} -seed ${seed} < ${dir1}rossler.dat > ${dir3}rossler_noise_i${i}.dat
  # LIFに入力する
  #echo -n "lif  "  # 明示的に変数を与える
  ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir2}rossler_bias.dat > ${dir2}rossler_lif_k${k}.dat
  # ISIを求める
  #echo -n "isi  "   
  ./isi < ${dir2}rossler_lif_k${k}.dat > ${dir2}rossler_isi_k${k}.dat
  # ISIの時系列長を参照
  isin=`head -n 1 ${dir2}rossler_isi_k${k}.dat | awk -F' ' '{print $3}'`
  echo "k= ${k} , isi1= ${isin}  "
  echo "${k} ${isin} " >> ${dir2}number_of_isi.dat
  




done #k








