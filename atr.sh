#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/10/08

# 1つのニューロンの
# 1 入力時系列
# 2 入力時系列 + ノイズ
# 3 ISI
# 4 再構成時系列
# の アトラクタ，RPを求める

# rossler->noise->lif->isi->再構成->RP->weight->dijkstra->多次元尺度法 


echo "///// atr.sh /////"
echo "///// one neuron /////"
p=-15 #SN比p
echo "p=$p"
seed=10 # seed値
k=0.3 # 漏れk
isin=0 # isiの時系列長
n=500 # n200 time99.8  n500 time248.8
#time=247.5 # k=0 p=0
time=267.0 # k=0.3 p=0 p=-15
#time=284.5 # k=0.5
dt=0.001 # 刻み幅
transient=1000 # 過渡状態
adjust=40 # 調整項
theta=0.1 # RPの閾値θ
dir="../2020-10/1008/"
#mkdir ${dir}
echo "/////  ${dir}  /////"
sampling=20 # 入力時系列用
#rm ${dir}pre.dat
rm ${dir}pre.dat
# レスラー方程式の第1変数x(t)
# ISIの時系列長n =500となるレスラーの時系列長を決め打ちする (=248.8くらい)
echo "///// input rossler /////"
# カオス応答
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust ${adjust} -sampling 1 > ${dir}rossler.dat
# 一定の入力
#./it 
# 周期応答
#./sin 
echo "time= ${time} "
while : # ノイズの大きさにより，ISI時系列長が変わる場合がある．
do
  # ノイズを加える
  echo -n "noise  "
  ./noise -p ${p} -seed ${seed} < ${dir}rossler.dat > ${dir}rossler_noise.dat
  # LIFに入力する
  echo -n "lif  "  
  ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir}rossler_noise.dat > ${dir}rossler_lif.dat
  # ISIを求める
  echo "isi  "   
  ./isi < ${dir}rossler_lif.dat > ${dir}rossler_isi.dat
  # ISIの時系列長を参照
  isin=`head -n 1 ${dir}rossler_isi.dat | awk -F' ' '{print $3}'`
  if [[ $isin -eq $n ]]; then
    # ISIからの再構成
    echo -n "reconstruct  " 
    ./reconstruct -m 5 -tau 1 < ${dir}rossler_isi.dat > ${dir}rossler_re.dat
    # RP
    echo "RP2  " 
    ./RP2 -theta ${theta} < ${dir}rossler_re.dat > ${dir}rossler_RP2.dat
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
./weight ${dir}rossler_RP2.dat > ${dir}rossler_w.dat
# dijkstra
echo -n "dijkstra  " # ok
./dijkstra < ${dir}rossler_w.dat > ${dir}rossler_d.dat
# CMDS
echo "CMDS  " #ok
Rscript predict.R ${dir}rossler_d.dat
awk -F' ' '{print $2}' ${dir}pre.dat > ${dir}pre_cmds.dat    # 2列目の抽出　1列目は番号なのでgnuplotで不要



echo "///// アトラクタとRP /////"
echo "/// 入力時系列 ///"
# 入力時系列 t-x(t) の保存
echo -n "rossler_tx  "
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 3 -adjust 0 -sampling 1 > ${dir}rossler_tx.dat
# 入力のRPを求める # gnuplotで図示
echo -n "ros  "
./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust 0 -sampling ${sampling} > ${dir}rossler_sample${sampling}.dat
echo -n "re 推定 " 
./reconstruct -m 5 -tau 15 < ${dir}rossler_sample${sampling}.dat > ${dir}rossler_sample${sampling}_re.dat
echo "RP "
./RP -theta 0.1 < ${dir}rossler_sample${sampling}_re.dat > ${dir}rossler_sample${sampling}_re_RP.dat

echo -n "re 推定 " 
./reconstruct -m 5 -tau 1 < ${dir}rossler_sample${sampling}.dat > ${dir}rossler_sample${sampling}_re_1.dat
echo "RP "
./RP -theta 0.1 < ${dir}rossler_sample${sampling}_re_1.dat > ${dir}rossler_sample${sampling}_re_1_RP.dat


echo -n "strange atractor "
./rossler -dt ${dt} -time ${time} -x0 0 -xyz 6 -sampling ${sampling} > ${dir}rossler_strange_sampling${sampling}.dat
echo "strange RP "
./RP -theta 0.1 < ${dir}rossler_strange_sampling${sampling}.dat > ${dir}rossler_strange_sampling${sampling}_RP.dat


echo "/// 入力時系列 + ノイズ ///"
./match -dt ${dt} < ${dir}rossler_noise.dat > ${dir}rossler_noise_tx.dat
./sampling -sample ${sampling} < ${dir}rossler_noise.dat > ${dir}rossler_noise_sample${sampling}.dat
./reconstruct -m 5 -tau 1 < ${dir}rossler_noise_sample${sampling}.dat > ${dir}rossler_noise_re.dat
./RP -theta 0.1 < ${dir}rossler_noise_re.dat > ${dir}rossler_noise_re_RP.dat

echo "/// ISI ///"
./reconstruct -m 5 -tau 1 < ${dir}rossler_isi.dat > ${dir}rossler_isi_re.dat
./RP -theta 0.1 < ${dir}rossler_isi_re.dat > ${dir}rossler_isi_re_RP.dat

echo "/// 再構成時系列 ///"
./reconstruct -m 5 -tau 1 < ${dir}pre_cmds.dat > ${dir}pre_cmds_re.dat
./RP -theta 0.1 < ${dir}pre_cmds_re.dat > ${dir}pre_cmds_re_RP.dat



echo "///// 重ね書き /////"
echo "/// 入力時系列 ///"
echo "time=${time}"
./standardize2 < ${dir}rossler_tx.dat > ${dir}rossler_tx_sta.dat ###3 ## 重ね書き

echo "/// 入力時系列 + ノイズ ///"
./standardize < ${dir}rossler_noise.dat > ${dir}rossler_noise_sta.dat ###3 ## 重ね書き
./match -dt ${dt} < ${dir}rossler_noise_sta.dat > ${dir}rossler_noise_sta_match.dat

echo "/// ISI ///"
./standardize < ${dir}rossler_isi.dat > ${dir}rossler_isi_sta.dat ###3 ## 重ね書き
isimatch=$(($time / $isin))
echo "isimatch=${isimatch}"
./match -dt ${isimatch} < ${dir}rossler_isi_sta.dat > ${dir}rossler_isi_sta_match.dat
./minus2 < ${dir}rossler_isi_sta_match.dat > ${dir}rossler_isi_sta_match_mi.dat

echo "/// 再構成時系列 ///"
./standardize < ${dir}pre_cmds.dat > ${dir}pre_cmds_sta.dat ###3 ## 重ね書き
pren=$(($isin - 4))
prematch=$(($time / $pren)) # 入力時系列長と再構成時系列の比をとって再構成時系列の刻み幅を調節する
echo "prematch=${prematch}"
./match -dt ${prematch} < ${dir}pre_cmds_sta.dat > ${dir}pre_cmds_sta_match.dat
./minus2 < ${dir}pre_cmds_sta_match.dat > ${dir}pre_cmds_sta_match_mi.dat



