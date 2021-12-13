#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/09/20
# エノン写像の時系列の再構成
# henon→RP→weight→dijkstra→多次元尺度法
# 論文”Production of Distance matrices and original time series from recurrence plots and their applications”の追試
rm pre.dat
# エノン写像の時系列の生成（長さn=7）
./henon -t 7 -skip 1 > henon.dat
# RPの作成　プロット割合50%を閾値とする
./rp2 -theta 0.5 < henon.dat > henonrp2.dat
# gnuplot: plot [-0.5:6.5][-0.5:6.5]"a.dat" with points pointtype 5 pointsize 1 notitle
# RPから重み付きネットワークを作成する
./weight henonrp2.dat > henonw.dat
# 重み付きネットワークから距離行列を求める
./dijkstra < henonw.dat > henondijk.dat
# 距離行列から時系列の再構成
Rscript predict.R henondijk.dat
# 2列目の抽出　1列目は番号なのでgnuplotで不要
cat pre.dat | awk -F" " '{print $2}' > henonpre.dat
# gnuplot: plot [0:6][-1.5:1.5]"a2.dat" u 1 w lp notitle
./standardize < henon.dat > henon_sta.dat
#./match -dt 0.01 < henon_sta.dat > henon_m.dat 
./standardize < henonpre.dat > henonpre_sta.dat
#./match -dt 0.66 < henonpre_sta.dat > henonpre_m.dat
