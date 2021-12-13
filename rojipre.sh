#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/09/22
# ロジスティック写像の時系列の再構成
# roji→再構成→RP→weight→dijkstra→多次元尺度法
# 論文”Production of Distance matrices and original time series from recurrence plots and their applications”の追試
rm ${dir}pre.dat

n=500
theta=0.1
dir="./roji_CMDS/"
echo $n $theta
# ロジスティック写像の時系列の生成（長さn=500）
echo roji 
./mtrand -n ${n} > ${dir}roji.dat
# RPの作成　プロット割合50%を閾値とする
echo RP
./rp2 -theta ${theta} < ${dir}roji.dat > ${dir}roji_rp2.dat
./rp -theta ${theta} < ${dir}roji.dat > ${dir}roji_rp.dat
# gnuplot: plot [-0.5:6.5][-0.5:6.5]"a.dat" with points pointtype 5 pointsize 1 notitle
# RPから重み付きネットワークを作成する
echo weight
./weight ${dir}roji_rp2.dat > ${dir}roji_w.dat
# 重み付きネットワークから距離行列を求める
echo dijkstra
./dijkstra < ${dir}roji_w.dat > ${dir}roji_d.dat
# 距離行列から時系列の再構成
echo CMDS
Rscript predict.R ${dir}roji_d.dat
# 2列目の抽出　1列目は番号なのでgnuplotで不要
cat ${dir}pre.dat | awk -F" " '{print $2}' > ${dir}roji_pre.dat
./minus < ${dir}roji_pre.dat > ${dir}roji_pre_mi.dat
# gnuplot: plot [0:6][-1.5:1.5]"a2.dat" u 1 w lp notitle
# 元の時系列と再構成時系列の重ね書き用 → gnuplot
echo standardize
./standardize < ${dir}roji.dat > ${dir}roji_sta.dat
#./match -dt 0.01 < ${dir}roji_sta.dat > ${dir}roji_m.dat 
./standardize < ${dir}roji_pre.dat > ${dir}roji_pre_sta.dat
./minus < ${dir}roji_pre_sta.dat > ${dir}roji_pre_sta_mi.dat
#./match -dt 0.01 < ${dir}roji_pre_sta.dat > ${dir}roji_pre_m.dat
