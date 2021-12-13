#!/usr/bin/zsh
# LIFsl.sh
# 作成者: Ei Miura
# 最終更新日: 2020/11/18
# LIFモデルの漏れkとを変化させた場合に
# 膜電位時系列V(t) がどのように変化するか調べる

# (rossler->noise->lif->isi->再構成->RP)*n→RPs→RPth->weight->dijkstra->多次元尺度法 

echo "///// LIFsl.sh /////"


# ///// パラメータ /////
# rossler
time=250
dt=0.001
transient=1000
adjust=40
sampling=20
# noise
p=-15
seed=10
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
dir1="../2020-11/1118-2/"
echo "///// ${dir1} /////"



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




echo "///// change num of neuron /////"

  touch ${dir1}number_of_isi_per_k.dat 
  
  echo "///// change value of k /////"
  # LIFモデルの漏れkを変える
  for k in `./num -start 0.0 -dt 0.1 -time 2.41` 
  do
    dir3="${dir1}k${k}/"
    mkdir ${dir3}
    #echo "# i isin " > ${dir3}number_of_isi.dat
    cp ${dir1}rossler_tx.dat ${dir3} #共通入力をコピー

    
    echo "///// k=${k} neuron /////"
    # n個のニューロンへノイズを加えた後，入力する
    # noise-> LIF-> ISI

    # ノイズを加える
    echo -n "noise  "
    ./noise -p ${p} -seed ${seed} < ${dir1}rossler.dat > ${dir3}rossler_noise.dat
    ./match -start 0 -end ${time} < ${dir3}rossler_noise.dat > ${dir3}rossler_noise_tx.dat

    # LIFに入力する
    echo -n "lif  "  
    # 発火時刻時系列
    #./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir1}rossler.dat > ${dir3}rossler_lif.dat
    ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir3}rossler_noise.dat > ${dir3}rossler_lif.dat
    # 膜電位時系列
    #./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} -v 1 < ${dir1}rossler.dat > ${dir3}rossler_Vt.dat
    ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} -v 1 < ${dir3}rossler_noise.dat > ${dir3}rossler_Vt.dat
  
    # ISIを求める
    echo  "isi  "   
    ./isi < ${dir3}rossler_lif.dat > ${dir3}rossler_isi.dat
    
    # ISIの時系列長を参照
    isin=`head -n 1 ${dir3}rossler_isi.dat | awk -F' ' '{print $3}'`
    echo "${k} ${isin} " >> ${dir1}number_of_isi_per_k.dat


    # x(t)とISIの重ね書き?

    # rossler_tx.dat と isi
    # rossler
    ./standardize2 < ${dir1}rossler_tx.dat > ${dir3}rossler_tx_sta.dat
    
    ./standardize < ${dir3}rossler_isi.dat > ${dir3}rossler_isi_sta.dat
    ./match -start 0 -end ${time} < ${dir3}rossler_isi_sta.dat > ${dir3}rossler_isi_sta_m.dat
    ./minus2 < ${dir3}rossler_isi_sta_m.dat > ${dir3}rossler_isi_sta_m_mi.dat


  done #k








