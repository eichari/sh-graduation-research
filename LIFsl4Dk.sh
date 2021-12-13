#!/usr/bin/zsh
# LIFsl4Dk.sh
# 作成者: Ei Miura
# 最終更新日: 2020/11/27
# LIFモデルの漏れkを変化させた場合に
# 共通の入力の情報を補えるか調べる

# (rossler->noise->lif->isi->再構成->RP)*n→RPs→RPth->weight->dijkstra->多次元尺度法 

echo "///// LIFsl4Dk.sh /////"

# ///// パラメータ /////
# rossler
time=250
dt=0.001
transient=1000
adjust=0
sampling=20
# LIF
k=0.0
Theta=20
# RP
theta=0.1 # RPの閾値θ
# 重畳RP
#theta_plus=25 # 重畳RPの閾値
theta_plus=3 # 重畳RPの閾値


# k= 1.2, ... , 

echo "///// parameter /////"
echo "time= ${time}, dt=${dt}, transient=${transient}, adjust=${adjust}"
echo "p=${p}, seed=${seed}, k=${k}, Theta=${Theta}, theta=${theta}"
echo "theta_plus= ${theta_plus}"
echo "/////////////////////"



n1fire=500 # k=0.0 time=250 bias=40 でrossler_xtを入力とした場合のisiのデータ数
#bias=39.5 #40 #500
bias=50.35 #500
isimin=${n1fire}



# ディレクトリ
#dir1="../2020-11/1127/"
dir1="../2020-12/1222/RP/"
mkdir ${dir1}

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
./RP -theta 0.1 < ${dir1}rossler_sample${sampling}_re.dat > ${dir1}rossler_sample${sampling}_re_RP.dat


#dir="../2020-11/1120/"
#${dir}bias_per_k.dat

#echo "///// 25 neuron k=1.0周辺  /////"
echo "///// 5 neuron k=1.0周辺  /////"


for k in `./num -start 0.998 -dt 0.001 -time 1.002` 
#for k in `./num -start 0.99600 -dt 0.00012 -time 1.0018` 
do
  
  dir3="${dir1}k${k}/"
  mkdir ${dir3}
  cp ${dir1}rossler_tx.dat ${dir3} #共通入力をコピー


  echo -n "k=${k} "

  # バイアス項を加える
  ./bias -b ${bias} < ${dir1}rossler.dat > ${dir3}rossler_bias.dat
  # LIFに入力する
  echo -n "lif  "  
  ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir3}rossler_bias.dat > ${dir3}rossler_lif.dat
  # ISIを求める
  echo -n "isi  "   
  ./isi < ${dir3}rossler_lif.dat > ${dir3}rossler_isi.dat
  
  
  # ISIの時系列長を参照
  isin=`head -n 1 ${dir3}rossler_isi.dat | awk -F' ' '{print $3}'`
  #echo "${k} ${isin} " >> ${dir1}number_of_isi_per_k.dat
  echo -n "isin=${isin}  "

  echo "${k} ${isin} " >> ${dir1}number_of_isi_per_k.dat
    
  # ISIからアトラクタの再構成
  echo -n "reconstruct  " 
  ./reconstruct -m 5 -tau 1 < ${dir3}rossler_isi.dat > ${dir3}rossler_re.dat
  echo "RP  "
  ./RP2 -theta ${theta} < ${dir3}rossler_re.dat > ${dir3}rossler_RP2_k${k}.dat
  #cp ${dir3}rossler_RP2_k${k}.dat ${dir1}

  # 重ね書き
  # rossler
  ./standardize2 < ${dir3}rossler_tx.dat > ${dir3}rossler_tx_sta.dat
  # isi // kasanegaki // 
  ./standardize < ${dir3}rossler_isi.dat > ${dir3}rossler_isi_sta.dat
  ./match -start 0 -end ${time} < ${dir3}rossler_isi_sta.dat > ${dir3}rossler_isi_sta_m.dat
  ./minus2 < ${dir3}rossler_isi_sta_m.dat > ${dir3}rossler_isi_sta_m_mi.dat
done


#echo "///// RPth /////"
# 重畳RPの作成
s=2
echo -n "RPs  "
#./RPs ${dir1}k0.99600/rossler_RP2_k0.99600.dat ${dir1}k0.99612/rossler_RP2_k0.99612.dat > ${dir1}rossler_RPs_${s}.dat
./RPs ${dir1}k0.998/rossler_RP2_k0.998.dat ${dir1}k0.999/rossler_RP2_k0.999.dat > ${dir1}rossler_RPs_${s}.dat
#for k in `./num -start 0.2 -dt 0.1 -time 2.41` 
#for k in `./num -start 0.99624 -dt 0.00012 -time 1.0018` 
for k in `./num -start 0.999 -dt 0.001 -time 1.002` 
do
  dir3="${dir1}k${k}/"
  i=${s}
  s=$((${s} + 1))
  ./RPs ${dir3}rossler_RP2_k${k}.dat ${dir1}rossler_RPs_${i}.dat > ${dir1}rossler_RPs_${s}.dat
done
cat ${dir1}rossler_RPs_${s}.dat > ${dir1}rossler_RPs.dat
echo -n "RPth  "
./RPth -theta ${theta_plus} < ${dir1}rossler_RPs.dat > ${dir1}rossler_RPth.dat 

#echo "///  分裂の確認  ///"
echo -n "break or devide  : "
./RPtoXY ${dir1}rossler_RPth.dat > ${dir1}rossler_RPth_xy.dat
./bunretu < ${dir1}rossler_RPth_xy.dat > ${dir1}rossler_RPth_bunretu.dat

devide=`cat ${dir1}rossler_RPth_bunretu.dat | sed '/^#/d' `

if [[ ${devide} -eq 1 ]]; then
  echo "one "
else
  echo "devide "
fi


echo "///// jikeiretu saikousei /////"
# weight
echo -n "weight  " # ok
./weight ${dir1}rossler_RPth.dat > ${dir1}rossler_w.dat
# dijkstra
echo -n "dijkstra  " # ok
./dijkstra < ${dir1}rossler_w.dat > ${dir1}rossler_d.dat
# CMDS
echo "CMDS  " #ok
rm ${dir1}pre.dat
Rscript predict50.R ${dir1}rossler_d.dat
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
isimin4=$((${isimin} - 5))

./just -n_pre ${isimin4} -ch 2 < ${dir1}rossler_tx_sta.dat > ${dir1}rossler_tx_sta_j.dat
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









