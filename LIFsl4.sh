#!/usr/bin/zsh
# LIFsl.sh
# 作成者: Ei Miura
# 最終更新日: 2020/11/12
# LIFモデルの漏れkと重畳数（ニューロン数）を変化させた場合に
# 共通の入力の情報を補えるか調べる

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
dir1="../2020-11/1113-4/"
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
# ニューロン数（重畳数）を変える
for n in 10 50 100 
do
  dir2="${dir1}n${n}/"
  mkdir ${dir2}
  
  touch ${dir1}st_k_n${n}.dat
  touch ${dir1}st_mi_k_n${n}.dat
  touch ${dir1}st_ex_k_n${n}.dat
  touch ${dir1}st_mi_ex_k_n${n}.dat
  touch ${dir1}st_ex_kit_k_n${n}.dat
  touch ${dir1}st_mi_ex_kit_k_n${n}.dat

  touch ${dir1}number_of_isi_per_k_n${n}.dat 
  touch ${dir1}RP_of_theta_per_k_n${n}.dat
  
  echo "///// change value of k /////"
  # LIFモデルの漏れkを変える
  for k in `./num -start 0.0 -dt 0.1 -time 2.41` 
  do
    dir3="${dir2}k${k}/"
    mkdir ${dir3}
    touch ${dir3}number_of_isi.dat
    #echo "# i isin " > ${dir3}number_of_isi.dat
    cp ${dir1}rossler_tx.dat ${dir3} #共通入力をコピー

    
    echo "///// n=${n} k=${k} neuron /////"
    # 重畳RP
    theta_plus=$((${n} / 2)) #theta_plus=5 # 重畳RPの閾値
    echo "theta_plus=${theta_plus}"

    # n個のニューロンへノイズを加えた後，入力する
    # noise-> LIF-> ISI
  
    for i in `seq 1 ${n}`
    do
      seed=$((${seed} + 1)) #$((${i} + 1))
      echo -n "i/n=${i}/${n} : seed=${seed} "

      # ノイズを加える
      echo -n "noise  "
      ./noise -p ${p} -seed ${seed} < ${dir1}rossler.dat > ${dir3}rossler_noise_i${i}.dat
      # LIFに入力する
      echo -n "lif  "  
      ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir3}rossler_noise_i${i}.dat > ${dir3}rossler_lif_i${i}.dat
      # ISIを求める
      echo  "isi  "   
      ./isi < ${dir3}rossler_lif_i${i}.dat > ${dir3}rossler_isi_i${i}.dat
      
      
      # ISIの時系列長を参照
      isin=`head -n 1 ${dir3}rossler_isi_i${i}.dat | awk -F' ' '{print $3}'`
      echo "${i} ${isin} " >> ${dir3}number_of_isi.dat
    done

    # ノイズの影響でISIの数が異なるので，最も少ないISIの数に合わせないといけない
    # isimin=データ数が最も少ないISI
    isimin=`./min2 -ch 2 < ${dir3}number_of_isi.dat`
    echo "isimin=${isimin}"

    # 各nにおける各kでの発火間隔時系列のデータ数をまとめる
    isidatanum=`head -n 1 ${dir3}number_of_isi.dat | awk -F' ' '{print $2}' `
    echo "${k} ${isidatanum} " >> ${dir1}number_of_isi_per_k_n${n}.dat 


    for i in `seq 1 ${n}`
    do
      echo -n "i/n=${i}/${n} : "

      # n個のISIの数を合わせる
      ./cut -c ${isimin} < ${dir3}rossler_isi_i${i}.dat > ${dir3}rossler_isi_i${i}_cut.dat
            
      # ISIからの再構成
      echo "reconstruct  " 
      ./reconstruct -m 5 -tau 1 < ${dir3}rossler_isi_i${i}_cut.dat > ${dir3}rossler_re_i${i}.dat
    done
    
    echo "///// RP roop /////"
    #///////////////////////////// 時系列の再構成ができるまでRPの変化させる //////////////////////////////
    for theta in `./num -start 0.1 -dt 0.01 -time 1.001`
    do
      echo -n "theta=${theta}  "
      # RP
      echo -n "RP2  " 
      for i in `seq 1 ${n}`
      do
        ./RP2 -theta ${theta} < ${dir3}rossler_re_i${i}.dat > ${dir3}rossler_RP2_i${i}.dat
      done
      
      #echo "///// RPth /////"
      # 重畳RPの作成
      echo -n "RPs  "
      ./RPs ${dir3}rossler_RP2_i1.dat ${dir3}rossler_RP2_i2.dat > ${dir3}rossler_RPs_2.dat
      for i in `seq 3 ${n}`
      do
        s=$((${i} - 1))
        # echo i=$i s=$s
        ./RPs ${dir3}rossler_RP2_i${i}.dat ${dir3}rossler_RPs_${s}.dat > ${dir3}rossler_RPs_${i}.dat
      done
      cat ${dir3}rossler_RPs_${n}.dat > ${dir3}rossler_RPs.dat
      echo -n "RPth  "
      ./RPth -theta ${theta_plus} < ${dir3}rossler_RPs.dat > ${dir3}rossler_RPth.dat 
      
      #echo "///  分裂の確認  ///"
      echo -n "break or devide  : "
      ./RPtoXY ${dir3}rossler_RPth.dat > ${dir3}rossler_RPth_xy.dat
      ./bunretu < ${dir3}rossler_RPth_xy.dat > ${dir3}rossler_RPth_bunretu.dat

      devide=`cat ${dir3}rossler_RPth_bunretu.dat | sed '/^#/d' `

      if [[ ${devide} -eq 1 ]]; then
        echo "${k} ${theta} " >> ${dir1}RP_of_theta_per_k_n${n}.dat
        echo "break "
        break
      else
        echo "devide "
      fi
    done
    #///////////////////////////////////////////////////////////////////////////////////
    
    echo "///// jikeiretu saikousei /////"
    # weight
    echo "weight  " # ok
    ./weight ${dir3}rossler_RPth.dat > ${dir3}rossler_w.dat
    # dijkstra
    echo "///// n=${n} k=${k} p=${p} /////"
    echo -n "dijkstra  " # ok
    ./dijkstra < ${dir3}rossler_w.dat > ${dir3}rossler_d.dat
    # CMDS
    echo "CMDS  " #ok
    rm ${dir1}pre.dat
    Rscript predict.R ${dir3}rossler_d.dat
    cp ${dir1}pre.dat ${dir3}
    awk -F' ' '{print $2}' ${dir1}pre.dat > ${dir3}pre_cmds.dat
    

#    #ここで，1番目の値が負なら正にする処理を行えば良い
#    pre1=`head -n 1 ${dir3}pre.dat | awk -F' ' '{print $2}'`
#    if [[ ${pre1} -lt 0 ]]; then # pre1<0
#      ./minus2 < ${dir3}pre.dat > ${dir3}pre_temp.dat
#      cp ${dir3}pre_temp.dat ${dir3}pre.dat
#    fi    
#    # 2列目の抽出　1列目は番号なのでgnuplotで不要
#    awk -F' ' '{print $2}' ${dir3}pre.dat > ${dir3}pre_cmds.dat
#    ./minus < ${dir3}pre_cmds.dat > ${dir3}pre_cmds_mi.dat



    echo "///// 重ね書き /////"
    # 重ね書き
    # rossler_tx.dat と pre_cmds_m.dat
    # rossler
    ./standardize2 < ${dir1}rossler_tx.dat > ${dir3}rossler_tx_sta.dat
    # pre.dat
    #isimin4=$((${isimin} - 4))
    isimin4=$((${isimin} - 5))

    isimatch=`echo "${time} / ${isimin4}" | bc -l`
    c=`echo 0${isimatch}`

    echo "/// time= ${time} , isimin4= ${isimin4} , c= ${c} ///"
    
    ./standardize < ${dir3}pre_cmds.dat > ${dir3}pre_cmds_sta.dat
    ./match -dt ${c} < ${dir3}pre_cmds_sta.dat > ${dir3}pre_cmds_sta_m.dat
    ./minus2 < ${dir3}pre_cmds_sta_m.dat > ${dir3}pre_cmds_sta_m_mi.dat

    # isi
    isimatch=`echo "${time} / ${isimin}" | bc -l`
    c2=`echo 0${isimatch}`    
    echo "/// time= ${time} , isimin= ${isimin} , c2= ${c2} ///"

    for i in `seq 1 ${n}`
    do
      ./match -dt ${c2} < ${dir3}rossler_isi_i${i}_cut.dat >${dir3}rossler_isi_i${i}_cut_m.dat
      ./standardize2 < ${dir3}rossler_isi_i${i}_cut_m.dat > ${dir3}rossler_isi_i${i}_cut_m_sta.dat
      ./minus2 < ${dir3}rossler_isi_i${i}_cut_m_sta.dat > ${dir3}rossler_isi_i${i}_cut_m_sta_mi.dat
    done

    # n個のisiの平均をとる
    touch ${dir3}temp_i0.dat
    for i in `seq 1 ${n}`
    do  
      j=$((${i} - 1))
      cat ${dir3}rossler_isi_i${i}_cut.dat | sed '/^#/d' | awk -F' ' '{print $1}' > ${dir3}rossler_isi_i${i}_cut_nc.dat
      paste -d , ${dir3}rossler_isi_i${i}_cut_nc.dat ${dir3}temp_i${j}.dat > ${dir3}temp_i${i}.dat
    done
    cat ${dir3}temp_i${n}.dat | sed "s/$/,/" | sed "s/,/ /g" > ${dir3}rossler_isi_iall.dat
    ./line_mean < ${dir3}rossler_isi_iall.dat > ${dir3}rossler_isi_mean.dat

    ./match -dt ${c2} < ${dir3}rossler_isi_mean.dat > ${dir3}rossler_isi_mean_m.dat
    ./standardize2 < ${dir3}rossler_isi_mean_m.dat > ${dir3}rossler_isi_mean_m_sta.dat
    ./minus2 < ${dir3}rossler_isi_mean_m_sta.dat > ${dir3}rossler_isi_mean_m_sta_mi.dat








    echo "///// 相関係数 /////"  # 相関係数
    # データの加工　　調整　極値　除去
    # データ数の調整   # rosslerのデータ数をpre.datに合わせる
    ./just -n_pre ${isimin4} -ch 2 < ${dir3}rossler_tx_sta.dat > ${dir3}rossler_tx_sta_j.dat
    # 極値の抽出
    ./extremum2 < ${dir3}rossler_tx_sta_j.dat > ${dir3}rossler_tx_sta_j_ex.dat 
    ./extremum2 < ${dir3}pre_cmds_sta_m.dat > ${dir3}pre_cmds_sta_m_ex.dat
    ./extremum2 < ${dir3}pre_cmds_sta_m_mi.dat > ${dir3}pre_cmds_sta_m_mi_ex.dat
    # 極値を1つ取る
    ./kit -c 1 -ch 2 < ${dir3}rossler_tx_sta_j_ex.dat > ${dir3}rossler_tx_sta_j_ex_kit.dat
    ./kit -c 1 -ch 2 < ${dir3}pre_cmds_sta_m_ex.dat >${dir3}pre_cmds_sta_m_ex_kit.dat
    ./kit -c 1 -ch 2 < ${dir3}pre_cmds_sta_m_mi_ex.dat >${dir3}pre_cmds_sta_m_mi_ex_kit.dat

    # st.c を使用したいので，コメント文と1行目の削除
    cat ${dir3}rossler_tx_sta_j.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}rossler_tx_sta_j_nc.dat
    cat ${dir3}rossler_tx_sta_j_ex.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}rossler_tx_sta_j_ex_nc.dat
    cat ${dir3}rossler_tx_sta_j_ex_kit.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}rossler_tx_sta_j_ex_kit_nc.dat
    cat ${dir3}pre_cmds_sta_m.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}pre_cmds_sta_m_nc.dat
    cat ${dir3}pre_cmds_sta_m_mi.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}pre_cmds_sta_m_mi_nc.dat
    cat ${dir3}pre_cmds_sta_m_ex.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}pre_cmds_sta_m_ex_nc.dat
    cat ${dir3}pre_cmds_sta_m_mi_ex.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}pre_cmds_sta_m_mi_ex_nc.dat
    cat ${dir3}pre_cmds_sta_m_ex_kit.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}pre_cmds_sta_m_ex_kit_nc.dat
    cat ${dir3}pre_cmds_sta_m_mi_ex_kit.dat | sed '/^#/d' | awk -F' ' '{print $2}' > ${dir3}pre_cmds_sta_m_mi_ex_kit_nc.dat


    # 相関係数　　調整　極値　除去
    # データ数を合わせただけ
    ./st ${dir3}rossler_tx_sta_j_nc.dat ${dir3}pre_cmds_sta_m_nc.dat > ${dir3}st.dat
    ./st ${dir3}rossler_tx_sta_j_nc.dat ${dir3}pre_cmds_sta_m_mi_nc.dat > ${dir3}st_mi.dat

    # 極値抽出
    ./st ${dir3}rossler_tx_sta_j_ex_nc.dat ${dir3}pre_cmds_sta_m_ex_nc.dat > ${dir3}st_ex.dat
    ./st ${dir3}rossler_tx_sta_j_ex_nc.dat ${dir3}pre_cmds_sta_m_mi_ex_nc.dat > ${dir3}st_mi_ex.dat

    # 極値抽出 かつ rosslerからデータを1つとる
#    ./st ${dir3}rossler_tx_sta_j_ex_kit_nc.dat ${dir3}pre_cmds_sta_m_ex_kit_nc.dat > ${dir3}st_ex_kit.dat
#    ./st ${dir3}rossler_tx_sta_j_ex_kit_nc.dat ${dir3}pre_cmds_sta_m_mi_ex_kit_nc.dat > ${dir3}st_mi_ex_kit.dat


    #相関係数をまとめる  #st.cでコメント表示しないようにした
    # ${dir2}st_k.dat
    st=`cat ${dir3}st.dat`
    echo "${k} ${st} " >> ${dir1}st_k_n${n}.dat
    # ${dir2}st_mi_k.dat
    st=`cat ${dir3}st_mi.dat`
    echo "${k} ${st} " >> ${dir1}st_mi_k_n${n}.dat

    # ${dir2}st_ex_k.dat
    st=`cat ${dir3}st_ex.dat`
    echo "${k} ${st} " >> ${dir1}st_ex_k_n${n}.dat
    # ${dir2}st_mi_ex_k.dat
    st=`cat ${dir3}st_mi_ex.dat`
    echo "${k} ${st} " >> ${dir1}st_mi_ex_k_n${n}.dat

    # ${dir2}st_ex_kit_k.dat
    st=`cat ${dir3}st_ex_kit.dat`
    echo "${k} ${st} " >> ${dir1}st_ex_kit_k_n${n}.dat
    # ${dir2}st_mi_ex_kit_k.dat
    st=`cat ${dir3}st_mi_ex_kit.dat`
    echo "${k} ${st} " >> ${dir1}st_mi_ex_kit_k_n${n}.dat



  done #k

done #n








