#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/12/21
# 膜電位の初期値を個体差としたLIFのISIのアトラクタを重ね合わせて共通入力を再構成するシェル


echo "///// LIFv0.sh /////"

# ///// パラメータ /////
# rossler
time=250
dt=0.001
transient=1000
adjust=0
sampling=20
# LIF
k=1.0
Theta=20
# RP
theta=0.1 # RPの閾値θ
# 
bias=40

# ディレクトリ
#dir1="../2020-12/1218/ISIの変化の確認/"
#dir1="../2020-12/1218/ISIの変化の確認k=1.0/"
dir1="../2020-12/1219/k=1.0bias=${bias}time=${time}/"
#dir1="../2020-12/1218/V(0)/"


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
echo -n "re "
./reconstruct -m 5 -tau 15 < ${dir1}rossler_sample${sampling}.dat > ${dir1}rossler_sample${sampling}_re.dat
echo "RP"
#./RP -theta 0.1 < ${dir1}rossler_sample${sampling}_re.dat > ${dir1}rossler_sample${sampling}_re_RP.dat

# バイアス項を加える
echo "bias "
./bias -b ${bias} < ${dir1}rossler.dat > ${dir1}rossler_bias.dat
./match -start 0 -dt ${dt} < ${dir1}rossler_bias.dat > ${dir1}rossler_tx_bias.dat

#for d in `./num -start 0.1 -dt 0.1 -time 0.11` 
#for d in 0 0.001 0.01 0.1
for vzero in 0 4 8 12 16
do
  dir2="${dir1}v0_${vzero}/"
  mkdir ${dir2}
  cp ${dir1}rossler_tx.dat ${dir2} #共通入力をコピー 重ね書き用
  cp ${dir1}rossler_bias.dat ${dir2}
  cp ${dir1}rossler_tx_bias.dat ${dir2}
  

  # LIFに入力する
  #echo -n "lif  "  
  ./LIF -v0 ${vzero} -Theta ${Theta} -k ${k} -time ${time} -dt ${dt} < ${dir2}rossler_bias.dat > ${dir2}rossler_lif_v0_${vzero}.dat
  ./LIF -v0 ${vzero} -Theta ${Theta} -k ${k} -time ${time} -dt ${dt} -v 1 < ${dir2}rossler_bias.dat > ${dir2}rossler_vt_v0_${vzero}.dat
  ./LIF -v0 ${vzero} -Theta ${Theta} -k ${k} -time ${time} -dt ${dt} -v 2 < ${dir2}rossler_bias.dat > ${dir2}rossler_spike_v0_${vzero}.dat
 
  # ISIを求め，アトラクタを再構成する
  #echo -n "isi  "   
  ./isi < ${dir2}rossler_lif_v0_${vzero}.dat > ${dir2}rossler_isi_v0_${vzero}.dat
  ./reconstruct -m 5 -tau 1 < ${dir2}rossler_isi_v0_${vzero}.dat > ${dir2}rossler_re_v0_${vzero}.dat
  # i番目の発火時刻とi番目の発火間隔を対応させたISI
  #./standardize2 < ${dir2}rossler_isi2_v0_${vzero}.dat > ${dir2}rossler_isi2_sta_v0_${vzero}.dat  
  #./reco2 -m 5 -tau 1 < ${dir2}rossler_isi2_sta_v0_${vzero}.dat > ${dir2}rossler_re2_sta_v0_${vzero}.dat
  #sed '/^#/d' ${dir2}rossler_re2_sta_v0_${vzero}.dat > ${dir2}rossler_re2_sta_v0_${vzero}_nc.dat
  ./isi2 < ${dir2}rossler_lif_v0_${vzero}.dat > ${dir2}rossler_isi2_v0_${vzero}.dat
  ./reco2 -m 5 -tau 1 < ${dir2}rossler_isi2_v0_${vzero}.dat > ${dir2}rossler_re2_v0_${vzero}.dat  
  sed '/^#/d' ${dir2}rossler_re2_v0_${vzero}.dat > ${dir2}rossler_re2_v0_${vzero}_nc.dat
  
  #cp ${dir2}rossler_re2_sta_v0_${vzero}_nc.dat ${dir1}
  cp ${dir2}rossler_re2_v0_${vzero}_nc.dat ${dir1}
  cp ${dir2}rossler_isi2_v0_${vzero}.dat ${dir1}
  cp ${dir2}rossler_spike_v0_${vzero}.dat ${dir1}
  cp ${dir2}rossler_vt_v0_${vzero}.dat ${dir1}
  
done

#cat ${dir1}rossler_re2_sta_v0_[0-9]_nc.dat ${dir1}rossler_re2_sta_v0_1[0-9]_nc.dat > ${dir1}rossler_re2_sta_v0_all.dat 
cat ${dir1}rossler_re2_v0_[0-9]_nc.dat ${dir1}rossler_re2_v0_1[0-9]_nc.dat > ${dir1}rossler_re2_v0_all.dat 
#cat ${dir1}rossler_re2_sta_k_0.0_nc.dat ${dir1}rossler_re2_sta_k_0.1_nc.dat ${dir1}rossler_re2_sta_k_0.2_nc.dat > ${dir1}rossler_re2_sta_k_all_nc.dat 

#ソート
#./lowsort < ${dir1}rossler_re2_sta_v0_all.dat > ${dir1}rossler_re2_sta_v0_sort.dat 
./lowsort < ${dir1}rossler_re2_v0_all.dat > ${dir1}rossler_re2_v0_sort.dat 
# コメント削除
#sed '/^#/d' ${dir1}rossler_re2_sta_v0_sort.dat > ${dir1}rossler_re2_sta_v0_sort_nc.dat 
sed '/^#/d' ${dir1}rossler_re2_v0_sort.dat > ${dir1}rossler_re2_v0_sort_nc.dat 

#1行目の発火時刻データを除去
#awk -F" " '{print $2" "$3" "$4" "$5" "$6" "}' ${dir1}rossler_re2_sta_v0_sort_nc.dat > ${dir1}sort.dat 
awk -F" " '{print $2" "$3" "$4" "$5" "$6" "}' ${dir1}rossler_re2_v0_sort_nc.dat > ${dir1}sort.dat 

echo "RP  "
./RP2 -theta ${theta} < ${dir1}sort.dat > ${dir1}rossler_RP2_sort.dat


#echo "///  分裂の確認  ///"
echo -n "break or devide  : "
./RPtoXY ${dir1}rossler_RP2_sort.dat > ${dir1}rossler_RP_sort_xy.dat
./bunretu < ${dir1}rossler_RP_sort_xy.dat > ${dir1}rossler_RP_sort_bunretu.dat

devide=`cat ${dir1}rossler_RP_sort_bunretu.dat | sed '/^#/d' `

if [[ ${devide} -eq 1 ]]; then
  echo "one "
else
  echo "devide "
fi


echo "///// jikeiretu saikousei /////"
# weight
echo -n "weight  " # ok
./weight ${dir1}rossler_RP2_sort.dat > ${dir1}rossler_sort_w.dat
# dijkstra
echo -n "dijkstra  " # ok
./dijkstra < ${dir1}rossler_sort_w.dat > ${dir1}rossler_sort_d.dat
# CMDS
echo "CMDS  " #ok
rm ${dir1}pre.dat
Rscript predict.R ${dir1}rossler_sort_d.dat
awk -F' ' '{print $2}' ${dir1}pre.dat > ${dir1}pre_cmds.dat







echo "///// 重ね書き /////"
# 重ね書き
# rossler_tx.dat と pre_cmds_m.dat
# rossler
./standardize2 < ${dir1}rossler_tx.dat > ${dir1}rossler_tx_sta.dat

# pre.dat    
./standardize < ${dir1}pre_cmds.dat > ${dir1}pre_cmds_sta.dat
./match -start 0 -end ${time} < ${dir1}pre_cmds_sta.dat > ${dir1}pre_cmds_sta_m.dat
./minus2 < ${dir1}pre_cmds_sta_m.dat > ${dir1}pre_cmds_sta_m_mi.dat

# isi // kasanegaki // 
#./standardize < ${dir1}rossler_isi.dat > ${dir1}rossler_isi_sta.dat
#./match -start 0 -end ${time} < ${dir1}rossler_isi_sta.dat > ${dir1}rossler_isi_sta_m.dat
#./minus2 < ${dir1}rossler_isi_sta_m.dat > ${dir1}rossler_isi_sta_m_mi.dat
    
    

echo "///// 相関係数 /////"  # 相関係数
# データの加工　　調整　極値　除去
# データ数の調整   # rosslerのデータ数をpre.datに合わせる
#isimin4=$((${isimin} - 4))

isin=`wc -l <  ${dir1}rossler_re2_v0_sort_nc.dat`

./just -n_pre ${isin} -ch 2 < ${dir1}rossler_tx_sta.dat > ${dir1}rossler_tx_sta_j.dat
# 極値の抽出
./extremum2 < ${dir1}rossler_tx_sta_j.dat > ${dir1}rossler_tx_sta_j_ex.dat 
./extremum2 < ${dir1}pre_cmds_sta_m.dat > ${dir1}pre_cmds_sta_m_ex.dat

# st.c を使用したいので，コメント文と1行目の削除
cat ${dir1}rossler_tx_sta_j.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir1}rossler_tx_sta_j_nc.dat
cat ${dir1}rossler_tx_sta_j_ex.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir1}rossler_tx_sta_j_ex_nc.dat
cat ${dir1}pre_cmds_sta_m.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir1}pre_cmds_sta_m_nc.dat
cat ${dir1}pre_cmds_sta_m_ex.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir1}pre_cmds_sta_m_ex_nc.dat


# 相関係数　　調整　極値　除去
# データ数を合わせただけ
./st ${dir1}rossler_tx_sta_j_nc.dat ${dir1}pre_cmds_sta_m_nc.dat > ${dir1}st.dat

# 極値抽出
./st ${dir1}rossler_tx_sta_j_ex_nc.dat ${dir1}pre_cmds_sta_m_ex_nc.dat > ${dir1}st_ex.dat

# 絶対値
./abs < ${dir1}st.dat > ${dir1}st_abs.dat
./abs < ${dir1}st_ex.dat > ${dir1}st_ex_abs.dat



