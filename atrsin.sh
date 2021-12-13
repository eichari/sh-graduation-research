#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/10/13

# 1つのニューロンの場合
# 1 周期応答
# 2 周期応答 + ノイズ
# 3 ISI
# 4 再構成時系列
# の アトラクタ，RPを求める

# sin->noise->lif->isi->再構成->RP->weight->dijkstra->多次元尺度法 


echo "///// atrsin.sh /////"
b=1.6
# 1周期 1.6 2周期 1.0 4周期 0.8 8周期 0.72
echo "///// one neuron /////"
p=-15 #SN比p
echo "p=$p"
seed=10 # seed値
k=0.3 # 漏れk
isin=0 # isiの時系列長
n=500 # n200 time99.8  n500 time248.8
#time=247.5 # k=0 p=0
#time=267.0 # k=0.3 p=0 p=-15
#time=268.0 # 周期応答 sin syuuki=100
time=271.3 # 周期応答 sin syuuki=10
#time=284.5 # k=0.5
dt=0.001 # 刻み幅
transient=1000 # 過渡状態
adjust=40 # 調整項
theta=0.1 # RPの閾値θ

syuuki=10 # 周期
dir="../2020-10/1017/sin10/"
#mkdir ${dir}
echo "/////  ${dir}  /////"
sampling=20 # 入力時系列用
#rm ${dir}pre.dat
rm ${dir}pre.dat
# レスラー方程式の第1変数x(t)
# ISIの時系列長n =500となるレスラーの時系列長を決め打ちする (=248.8くらい)
echo "///// input rossler /////"
# 周期応答
#./rossler -a 0.2 -b ${b} -c 5.7 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust ${adjust} -sampling 1 > ${dir}rossler.dat
./sin -time ${time} -dt ${dt} -A 6 -p ${syuuki} -adjust ${adjust} -ch 0 > ${dir}sin.dat 

echo "time= ${time} "
while : # ノイズの大きさにより，ISI時系列長が変わる場合がある．
do
  # ノイズを加える
  echo -n "noise  "
  ./noise -p ${p} -seed ${seed} < ${dir}sin.dat > ${dir}sin_noise.dat
  # LIFに入力する
  echo -n "lif  "  
  ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir}sin_noise.dat > ${dir}sin_lif.dat
  # ISIを求める
  echo "isi  "   
  ./isi < ${dir}sin_lif.dat > ${dir}sin_isi.dat
  # ISIの時系列長を参照
  isin=`head -n 1 ${dir}sin_isi.dat | awk -F' ' '{print $3}'`
  if [[ $isin -eq $n ]]; then
    # ISIからの再構成
    echo -n "reconstruct  " 
    ./reconstruct -m 5 -tau 1 < ${dir}sin_isi.dat > ${dir}sin_re.dat
    # RP
    echo "RP2  " 
    ./RP2 -theta ${theta} < ${dir}sin_re.dat > ${dir}sin_RP2.dat
    echo "isin=${isin}"
    break
  else
    seed=$(($seed + 10))
    echo "i=${i} seed=${seed} time=${time} isin=${isin} "
  fi
done
echo "////// seed end //////"



echo "///// jikeiretu saikousei /////"
# weight
echo -n "weight  " # ok
./weight ${dir}sin_RP2.dat > ${dir}sin_w.dat
# dijkstra
echo -n "dijkstra  " # ok
./dijkstra < ${dir}sin_w.dat > ${dir}sin_d.dat
# CMDS
echo "CMDS  " #ok
Rscript predict.R ${dir}sin_d.dat
awk -F' ' '{print $2}' ${dir}pre.dat > ${dir}pre_cmds.dat    # 2列目の抽出　1列目は番号なのでgnuplotで不要


./minus2 < ${dir}pre.dat > ${dir}pre_mi.dat #//
./minus < ${dir}pre_cmds.dat > ${dir}pre_cmds_mi.dat #//
./match -dt 1.0 -start 1.0 < ${dir}pre_cmds_mi.dat > ${dir}pre_mi.dat

./reconstruct -m 5 -tau 1 < ${dir}pre_cmds_mi.dat > ${dir}pre_cmds_mi_re.dat
./RP -theta 0.1 < ${dir}pre_cmds_mi_re.dat > ${dir}pre_cmds_mi_re_RP.dat




echo "///// アトラクタとRP /////"
echo "/// 入力時系列 ///"
# 入力時系列 t-x(t) の保存
echo -n "sin_tx  "
./sin -time ${time} -dt ${dt} -A 6 -p ${syuuki} -adjust 0 -ch 1 > ${dir}sin_tx.dat 
#./sin -time ${time} -dt ${dt} -A 6 -p ${syuuki} -adjust ${adjust} -ch 1 > ${dir}sin_40_tx.dat 
# 入力のRPを求める # gnuplotで図示
echo -n "sin sampling "
./sampling -sample ${sampling} < ${dir}sin.dat > ${dir}sin_sample${sampling}.dat
#./sin -time ${time} -dt ${dt} -A 6 -p 0.05 -adjust ${adjust} -ch 0 > ${dir}sin_sample${sampling}.dat


echo -n "re 推定 15 " 
./reconstruct -m 5 -tau 15 < ${dir}sin_sample${sampling}.dat > ${dir}sin_sample${sampling}_re.dat
echo "RP "
./RP -theta 0.1 < ${dir}sin_sample${sampling}_re.dat > ${dir}sin_sample${sampling}_re_RP.dat

echo -n "re 推定 1 " 
./reconstruct -m 5 -tau 1 < ${dir}sin_sample${sampling}.dat > ${dir}sin_sample${sampling}_re_1.dat
echo "RP "
./RP -theta 0.1 < ${dir}sin_sample${sampling}_re_1.dat > ${dir}sin_sample${sampling}_re_1_RP.dat


echo "/// 入力時系列 + ノイズ ///"
./match -dt ${dt} < ${dir}sin_noise.dat > ${dir}sin_noise_tx.dat
./sampling -sample ${sampling} < ${dir}sin_noise.dat > ${dir}sin_noise_sample${sampling}.dat
./reconstruct -m 5 -tau 1 < ${dir}sin_noise_sample${sampling}.dat > ${dir}sin_noise_re.dat
./RP -theta 0.1 < ${dir}sin_noise_re.dat > ${dir}sin_noise_re_RP.dat

echo "/// ISI ///"
./reconstruct -m 5 -tau 1 < ${dir}sin_isi.dat > ${dir}sin_isi_re.dat
./RP -theta 0.1 < ${dir}sin_isi_re.dat > ${dir}sin_isi_re_RP.dat

echo "/// 再構成時系列 ///"
./reconstruct -m 5 -tau 1 < ${dir}pre_cmds.dat > ${dir}pre_cmds_re.dat
./RP -theta 0.1 < ${dir}pre_cmds_re.dat > ${dir}pre_cmds_re_RP.dat


echo "///// 重ね書き /////"
echo "/// 入力時系列 ///"
echo "time=${time}"
./standardize2 < ${dir}sin_tx.dat > ${dir}sin_tx_sta.dat ###3 ## 重ね書き

echo "/// 入力時系列 + ノイズ ///"
./standardize < ${dir}sin_noise.dat > ${dir}sin_noise_sta.dat ###3 ## 重ね書き
./match -dt ${dt} < ${dir}sin_noise_sta.dat > ${dir}sin_noise_sta_match.dat

echo "/// ISI ///"
./standardize < ${dir}sin_isi.dat > ${dir}sin_isi_sta.dat ###3 ## 重ね書き
isimatch=$(($time / $isin))
echo "isimatch=${isimatch}"
./match -dt ${isimatch} < ${dir}sin_isi_sta.dat > ${dir}sin_isi_sta_match.dat
./minus2 < ${dir}sin_isi_sta_match.dat > ${dir}sin_isi_sta_match_mi.dat

echo "/// 再構成時系列 ///"
./standardize < ${dir}pre_cmds.dat > ${dir}pre_cmds_sta.dat ###3 ## 重ね書き
pren=$(($isin - 4))
prematch=$(($time / $pren)) # 入力時系列長と再構成時系列の比をとって再構成時系列の刻み幅を調節する
echo "prematch=${prematch}"
./match -dt ${prematch} < ${dir}pre_cmds_sta.dat > ${dir}pre_cmds_sta_match.dat
./minus2 < ${dir}pre_cmds_sta_match.dat > ${dir}pre_cmds_sta_match_mi.dat


