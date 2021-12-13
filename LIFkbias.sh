#!/usr/bin/zsh
# LIFkbias.sh
# 作成者: Ei Miura
# 最終更新日: 2020/11/19
# LIFモデルの漏れkとを変化させた場合に
# 膜電位時系列V(t) がどのように変化するか調べる

# (rossler->noise->lif->isi->再構成->RP)*n→RPs→RPth->weight->dijkstra->多次元尺度法 

echo "///// LIFkbias.sh /////"


# ///// パラメータ /////
# rossler
time=250
dt=0.001
transient=1000
adjust=40
sampling=20
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
dir1="../2020-11/1119/"
echo "///// ${dir1} /////"

touch ${dir1}number_of_isi_per_k.dat 
touch ${dir1}bias_per_k.dat 


# 共通入力
echo "///// 共通入力 /////"
# x(t) 共通入力
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient ${transient} -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust ${adjust} -sampling 1 > ${dir1}rossler.dat
echo "////// plot rossler //////"
# 入力時系列 t-x(t) の保存
echo -n "rossler_tx  "
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 3 -adjust 0 -sampling 1 > ${dir1}rossler_tx.dat
# 入力のRPを求める # gnuplotで図示
echo -n "ros  "
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust 0 -sampling ${sampling} > ${dir1}rossler_sample${sampling}.dat
echo "re "
./reconstruct -m 5 -tau 15 < ${dir1}rossler_sample${sampling}.dat > ${dir1}rossler_sample${sampling}_re.dat
#echo RP
#./RP -theta 0.1 < ${dir}rossler_sample${sampling}_re.dat > ${dir}rossler_sample${sampling}_re_RP.dat





n1fire=506 # k=0.0 time=250 bias=40 でrossler_xtを入力とした場合のisiのデータ数
bias=40




echo "///// change value of k /////"
# LIFモデルの漏れkを変化させる
for k in `./num -start 0.0 -dt 0.1 -time 2.41` 
do
  dir2="${dir1}k${k}/"
  mkdir ${dir2}

  

  while : #bias roop
  do
    echo -n "k=${k}  "
    echo -n "ros  "
    # x(t) 入力
    ./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient ${transient} -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust ${bias} -sampling 1 > ${dir2}rossler_bias.dat
    # LIFに入力する
    echo -n "lif  "  
    # 発火時刻時系列
    ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir2}rossler_bias.dat > ${dir2}rossler_lif.dat
#    ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir3}rossler_noise.dat > ${dir3}rossler_lif.dat
    # 膜電位時系列
    ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} -v 1 < ${dir2}rossler_bias.dat > ${dir2}rossler_Vt.dat
#    ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} -v 1 < ${dir3}rossler_noise.dat > ${dir3}rossler_Vt.dat
    # ISIを求める
    echo -n "isi  "   
    ./isi < ${dir2}rossler_lif.dat > ${dir2}rossler_isi.dat
    
    # ISIの時系列長を参照
    isin=`head -n 1 ${dir2}rossler_isi.dat | awk -F' ' '{print $3}'`
    #echo "${k} ${isin} " >> ${dir1}number_of_isi_per_k.dat
    echo -n "isin=${isin}  "

    # ISIのデータ数が
    if [[ ${isin} -eq ${n1fire} ]]; then
      echo "${k} ${isin} " >> ${dir1}number_of_isi_per_k.dat
      echo "${k} ${bias} " >> ${dir1}bias_per_k.dat
      echo "break "
      break
    else
#      bias=$((${bias} + 0.1))
      bias=`echo "${bias} + 0.05" | bc -l`

      echo "roop bias=${bias} "
    fi
    
  done #bias roop  

done #k



echo "///// change value of k /////"
# LIFモデルの漏れkを変える
for k in `./num -start 0.0 -dt 0.1 -time 2.41` 
do
  dir2="${dir1}k${k}/"

    # x(t)とISIの重ね書き?

    # rossler_tx.dat と isi
    # rossler
    cp ${dir1}rossler_tx.dat ${dir2}
    ./standardize2 < ${dir1}rossler_tx.dat > ${dir2}rossler_tx_sta.dat
    # isi
    ./standardize < ${dir2}rossler_isi.dat > ${dir2}rossler_isi_sta.dat
    ./match -start 0 -end ${time} < ${dir2}rossler_isi_sta.dat > ${dir2}rossler_isi_sta_m.dat
    ./minus2 < ${dir2}rossler_isi_sta_m.dat > ${dir2}rossler_isi_sta_m_mi.dat

done #k








