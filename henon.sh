#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/10/21
# エノン写像の時系列の再構成
# RPの閾値を変化させる

# henon→RP→weight→dijkstra→多次元尺度法
# 論文”Production of Distance matrices and original time series from recurrence plots and their applications”の追試

theta=0.1
for i in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0
do
  theta=${i}
  dir="../2020-10/1021/"
  dir2="../2020-10/1021/theta_${theta}/"

  mkdir ${dir2}
  echo "/////  ${dir}  /////"
  rm ${dir}pre.dat

  # エノン写像の時系列の生成（長さn=7）
  ./henon -time 7 -skip 1 > ${dir2}henon.dat
  # RPの作成　プロット割合50%を閾値とする
  ./RP2 -theta ${theta} < ${dir2}henon.dat > ${dir2}henon_RP2.dat
  # gnuplot: plot [-0.5:6.5][-0.5:6.5]"a.dat" with points pointtype 5 pointsize 1 notitle
  # RPから重み付きネットワークを作成する
  ./weight ${dir2}henon_RP2.dat > ${dir2}henon_w.dat
  # 重み付きネットワークから距離行列を求める
  ./dijkstra < ${dir2}henon_w.dat > ${dir2}henon_d.dat
  # 距離行列から時系列の再構成
  Rscript predict.R ${dir2}henon_d.dat
  # 2列目の抽出　1列目は番号なのでgnuplotで不要
  awk -F' ' '{print $2}' ${dir}pre.dat > ${dir2}pre_cmds.dat
  # gnuplot: plot [0:6][-1.5:1.5]"a2.dat" u 1 w lp notitle

  echo "/////  重ね書き  /////"
  ./standardize < ${dir2}henon.dat > ${dir2}henon_sta.dat
  #./match -dt 0.01 < henon_sta.dat > henon_m.dat 
  ./standardize < ${dir2}pre_cmds.dat > ${dir2}pre_cmds_sta.dat
  #./match -dt 0.66 < henonpre_sta.dat > henonpre_m.dat

  echo "/////  分裂の確認  /////"
  # ./RPtoXY ${dir2}henon_RP2.dat > ${dir2}henon_RP.dat
  ./RP -theta ${theta} < ${dir2}henon.dat > ${dir2}henon_RP.dat
  ./bunretu < ${dir2}henon_RP.dat > ${dir2}henon_bunretu.dat
  
  echo "/////  相関係数  /////"
  ./st ${dir2}henon_sta.dat ${dir2}pre_cmds_sta.dat > ${dir2}st.dat
  sed '/^#/d' ${dir2}st.dat >> ${dir}st_nocomment.dat # コメント文を消す
  ./match -dt 0.1 -start 0.1 < ${dir}st_nocomment.dat > ${dir}st_nocomment_m.dat
  ./match -dt 10 -start 10 < ${dir}st_nocomment.dat > ${dir}st_nocomment_m10.dat

done

