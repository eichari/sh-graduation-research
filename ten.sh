#!/usr/bin/zsh
# 作成者: Ei Miura
# 最終更新日: 2020/09/26
# 任意の数のニューロンのRPから重畳して入力時系列の再構成を行うシェル 

# (rossler->noise->lif->isi->再構成->RP)*n→RPs→RPth->weight->dijkstra->多次元尺度法 


#echo "///// ten.sh /////"
#10回平均を出す
#for ((m=0 ; m<10 ; m++))
#do
#  dirmean="./相関/0926/mean/10/10_mean_$m"
#  mkdir $dirmean
#  echo "///// mean${m} p${p} /////"
#  #p=0 # SN比
#  seed=$m # seed値
#　ニューロンの個数を変える
#for j in 10 50 100 
#do
  #for p in -15 -10 -5 0 5 10 15 20
  for p in -10 -5 5 10
  do
    j=10
    #p=0
    echo "///// ${j} neuron /////"
    #p=15 # SN比
    echo "p=$p"
    # seed=10 # seed値
    numseed=${j} # ニューロンの個数
    #k=0 # 漏れk
    k=0.3 # 漏れk
    theta_plus=$(($numseed / 2))
    #theta_plus=5 # 重畳RPの閾値θ
    echo "theta_plus=${theta_plus}"
    skip=1 # 省く 4 # 省かない 1
    isin=0 # isiの時系列長
    n=500 # n200 time99.8  n500 time248.8
    #time=247.5 # k=0 p=0
    time=267.5 # k=0.3 p=0 p=-15
    #time=284.5 # k=0.5
    dt=0.001 # 刻み幅
    transient=1000 # 過渡状態
    adjust=40 # 調整項
    theta=0.1 # RPの閾値θ
    dir="./相関/0926/追試/${j}個p=${p}/"
    #dir="./相関/0926/LIF/${j}個p=${p}k=${k}/" # 保存するディレクトリ
    mkdir ${dir}
    echo "/////  ${dir}  /////"
    sampling=20 # 入力時系列用
    #rm ${dir}pre.dat
    rm ./相関/0926/追試/pre.dat
    # レスラー方程式の第1変数x(t)
    # ISIの時系列長n =500となるレスラーの時系列長を決め打ちする (=248.8くらい)
    echo "///// input rossler /////"
    ./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust ${adjust} -sampling 1 > ${dir}rossler.dat
    echo "time= ${time} "
    echo "seed"
    for i in `seq 1 ${numseed}`
    do
      seed=$(($seed + ${i})) #$((${i} + 1))
      echo "i=${i} seed=${seed} j=${j}"
      while : # ノイズの大きさにより，ISI時系列長が変わる場合がある．
      do
        # ノイズを加える
        echo -n "noise  "
        ./noise -p ${p} -seed ${seed} < ${dir}rossler.dat > ${dir}rossler_noise_seed${i}.dat
        # LIFに入力する
        echo -n "lif  "  
        ./lif -Theta 20 -k ${k} -time ${time} -dt ${dt} < ${dir}rossler_noise_seed${i}.dat > ${dir}rossler_lif_seed${i}.dat
        # ISIを求める
        echo -n "isi  "   
        ./isi < ${dir}rossler_lif_seed${i}.dat > ${dir}rossler_isi_seed${i}.dat
        # ISIの時系列長を参照
        isin=`head -n 1 ${dir}rossler_isi_seed${i}.dat | awk -F' ' '{print $3}'`
        if [[ $isin -eq $n ]]; then
          break
        else
          seed=$(($seed + 10))
          echo "i=${i} seed=${seed} time=${time} isin=${isin} "
        fi
      done
      echo -n "isin=$isin time=$time  "
      # ISIからの再構成
      echo -n "reconstruct  " 
      ./reconstruct -m 5 -tau 1 < ${dir}rossler_isi_seed${i}.dat > ${dir}rossler_re_seed${i}.dat
      # RP
      echo "RP2  " 
      ./RP2 -theta ${theta} < ${dir}rossler_re_seed${i}.dat > ${dir}rossler_RP2_seed${i}.dat
    done
    echo "////// seed end //////"
    # 入力時系列 t-x(t) の保存
    echo -n "rossler_tx  "
    ./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 3 -adjust 0 -sampling 1 > ${dir}rossler_tx.dat
    # 入力のRPを求める # gnuplotで図示
    echo -n "ros  "
    ./rossler -a 0.36 -b 0.4 -c 4.5 -time ${time} -transient 1000 -dt ${dt} -x0 0 -y0 0 -z0 0 -xyz 4 -adjust 0 -sampling ${sampling} > ${dir}rossler_sample${sampling}.dat
    echo "re "
    ./reconstruct -m 5 -tau 15 < ${dir}rossler_sample${sampling}.dat > ${dir}rossler_sample${sampling}_re.dat
    #echo RP
    #./RP -theta 0.1 < ${dir}rossler_sample${sampling}_re.dat > ${dir}rossler_sample${sampling}_re_RP.dat

    echo "///// RPth /////"
    # 重畳RPの作成
    echo -n "RPs  "
    ./RPs ${dir}rossler_RP2_seed1.dat ${dir}rossler_RP2_seed2.dat > ${dir}rossler_RPs_2.dat
    for i in `seq 3 ${numseed}`
    do
      s=$((${i} - 1))
      # echo i=$i s=$s
      ./RPs ${dir}rossler_RP2_seed${i}.dat ${dir}rossler_RPs_${s}.dat > ${dir}rossler_RPs_${i}.dat
    done
    cat ${dir}rossler_RPs_${numseed}.dat > ${dir}rossler_RPs.dat
    echo "RPth  "
    ./RPth -theta ${theta_plus} < ${dir}rossler_RPs.dat > ${dir}rossler_RPth.dat 
    echo "///// jikeiretu saikousei /////"
    # weight
    echo -n "weight  " # ok
    ./weight ${dir}rossler_RPth.dat > ${dir}rossler_w.dat
    # dijkstra
    echo "///// mean${m} p${p} /////"
    echo -n "dijkstra  j=${j} " # ok
    ./dijkstra < ${dir}rossler_w.dat > ${dir}rossler_d.dat
    # CMDS
    echo -n "CMDS  " #ok
    #cp ${dir}rossler_noise_lif_isi_re_RP2_w_d.dat tmp.dat
    Rscript predict.R ${dir}rossler_d.dat
    cp ./相関/0926/追試/pre.dat ${dir}
    # mv pre.dat ${dir}
    # 2列目の抽出　1列目は番号なのでgnuplotで不要
    awk -F' ' '{print $2}' ${dir}pre.dat > ${dir}pre_cmds.dat
    ./minus < ${dir}pre_cmds.dat > ${dir}pre_cmds_mi.dat
    ./minus < ${dir}pre.dat > ${dir}pre_mi.dat



    # 標準化 入力と予測の時系列の重ね書き用
    echo "///// kasanegaki /////"
    # 入力時系列
    echo -n "hyoujunka  "
    ./standardize2 < ${dir}rossler_tx.dat > ${dir}rossler_tx_sta.dat ###3 ## 重ね書き
    # 再構成時系列
    pren=$(($isin - 4))
    mat=$(($time / $pren)) # 入力時系列長と再構成時系列の比をとって再構成時系列の刻み幅を調節する
    #match=$(($mat + 0.004))
    echo "match= $mat  "
    ./standardize < ${dir}pre_cmds.dat > ${dir}pre_cmds_sta.dat 
    ./match -dt $mat < ${dir}pre_cmds_sta.dat > ${dir}pre_cmds_sta_m.dat #####5 ###3  ## 重ね書き
    ./minus < ${dir}pre_cmds_sta.dat > ${dir}pre_cmds_sta_mi.dat # いらない？
    ./match -dt $mat < ${dir}pre_cmds_sta_mi.dat > ${dir}pre_cmds_sta_mim.dat # いらない？



    # 評価 # 正規化 相関係数 平均平方二乗誤差
    echo "///// hyouka /////"
    echo "///// input time series /////"
    npre=`wc -l < ${dir}pre10.dat` # npre : 再構成時系列のデータ数
    ./just -n_pre ${npre} < ${dir}rossler_tx.dat > ${dir}rossler_tx_j.dat # 入力時系列長を再構成時系列長に合わせる
    ./standardize2 < ${dir}rossler_tx_j.dat > ${dir}rossler_tx_j_sta.dat ##**
    ./normalize2 < ${dir}rossler_tx_j_sta.dat > ${dir}rossler_tx_j_sta_normal.dat #正規化
    ./kyokuti -skip ${skip} < ${dir}rossler_tx_j_sta_normal.dat > ${dir}rossler_tx_j_sta_normal_ex.dat
    #./kyokuti -skip 1 < ${dir}rossler_tx_j_sta_normal.dat > ${dir}rossler_tx_j_sta_normal_ex.dat # 省かない


    echo "///// reconstructed time series /////"
    #////// 多次元尺度法の符号 /////// ↓mi //////////////////
    # plus
    ./match -dt $mat < ${dir}pre_cmds.dat > ${dir}pre_t.dat
    ./standardize2 < ${dir}pre_t.dat > ${dir}pre_sta.dat ##**
    ./normalize2 < ${dir}pre_sta.dat > ${dir}pre_sta_normal.dat
    ./kyokuti -skip ${skip} < ${dir}pre_sta_normal.dat > ${dir}pre_sta_normal_ex.dat
    #./kyokuti -skip 1 < ${dir}pre_sta_normal.dat > ${dir}pre_sta_normal_ex.dat # 省かない

    # minus
    ./match -dt $mat < ${dir}pre_cmds_mi.dat > ${dir}pre_t_mi.dat
    ./standardize2 < ${dir}pre_t_mi.dat > ${dir}pre_sta_mi.dat ##**
    ./normalize2 < ${dir}pre_sta_mi.dat > ${dir}pre_sta_normal_mi.dat
    ./kyokuti -skip ${skip} < ${dir}pre_sta_normal_mi.dat > ${dir}pre_sta_normal_ex_mi.dat
    #./kyokuti -skip 1 < ${dir}pre_sta_normal.dat > ${dir}pre_sta_normal_ex.dat # 省かない


    #極値を抽出する前の相関
    #${dir}rossler_tx_j.dat 
    #${dir}pre_t.dat 
    echo "///// not ex /////" # 極値を抽出しない場合の相関
    echo "soukanzu st "
    sed '/^#/d' ${dir}rossler_tx_j_sta_normal.dat > ${dir}rossler_tx_j_sta_normal_nocomment.dat # コメント文を消す
    sed '/^#/d' ${dir}pre_sta_normal.dat > ${dir}pre_sta_normal_nocomment.dat # コメント文を消す
    awk -F' ' '{print $2}' ${dir}rossler_tx_j_sta_normal_nocomment.dat > ${dir}rossler_tx_j_sta_normal_nocomment_one.dat
    awk -F' ' '{print $2}' ${dir}pre_sta_normal_nocomment.dat > ${dir}pre_sta_normal_nocomment_one.dat
    ./soukanzu ${dir}rossler_tx_j_sta_normal_nocomment_one.dat ${dir}pre_sta_normal_nocomment_one.dat > ${dir}exex_notex.dat
    ./st ${dir}rossler_tx_j_sta_normal_nocomment_one.dat ${dir}pre_sta_normal_nocomment_one.dat > ${dir}st_notex.dat

    # 多次元尺度法 の向き調整 plus
    echo "///// ex plus /////" # 極値を抽出する場合の相関
    echo "soukanzu st "
    sed '/^#/d' ${dir}rossler_tx_j_sta_normal_ex.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment.dat # コメント文を消す
    sed '/^#/d' ${dir}pre_sta_normal_ex.dat > ${dir}pre_sta_normal_ex_nocomment.dat # コメント文を消す
    #sed '1d' ${dir}rossler_tx_j_sta_normal_ex_nocomment.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_t.dat
    # ///////////////////// 1つめの極値を取る /////////////////////// ↓t ////////////////
    awk -F' ' '{print $2}' ${dir}rossler_tx_j_sta_normal_ex_nocomment.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_one.dat
    awk -F' ' '{print $2}' ${dir}pre_sta_normal_ex_nocomment.dat > ${dir}pre_sta_normal_ex_nocomment_one.dat
    ./soukanzu ${dir}rossler_tx_j_sta_normal_ex_nocomment_one.dat ${dir}pre_sta_normal_ex_nocomment_one.dat > ${dir}exex.dat
    ./st ${dir}rossler_tx_j_sta_normal_ex_nocomment_one.dat ${dir}pre_sta_normal_ex_nocomment_one.dat > ${dir}st.dat

    # 多次元尺度法 の向き調整 minus
    echo "///// ex minus /////" # 極値を抽出する場合の相関
    echo "soukanzu st "
    #sed '/^#/d' ${dir}rossler_tx_j_sta_normal_ex_mi.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_mi.dat # コメント文を消す
    sed '/^#/d' ${dir}pre_sta_normal_ex_mi.dat > ${dir}pre_sta_normal_ex_nocomment_mi.dat # コメント文を消す
    #sed '1d' ${dir}rossler_tx_j_sta_normal_ex_nocomment.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_t.dat
    # ///////////////////// 1つめの極値を取る /////////////////////// ↓t ////////////////
    #awk -F' ' '{print $2}' ${dir}rossler_tx_j_sta_normal_ex_nocomment.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_one.dat
    awk -F' ' '{print $2}' ${dir}pre_sta_normal_ex_nocomment_mi.dat > ${dir}pre_sta_normal_ex_nocomment_one_mi.dat
    ./soukanzu ${dir}rossler_tx_j_sta_normal_ex_nocomment_one.dat ${dir}pre_sta_normal_ex_nocomment_one_mi.dat > ${dir}exex_mi.dat
    ./st ${dir}rossler_tx_j_sta_normal_ex_nocomment_one.dat ${dir}pre_sta_normal_ex_nocomment_one_mi.dat > ${dir}st_mi.dat

    # 入力時系列の1つめの極値をとる
    echo "///// ex sed /////"
    echo "soukanzu st "
    sed '1d' ${dir}rossler_tx_j_sta_normal_ex_nocomment.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_sed.dat
    awk -F' ' '{print $2}' ${dir}rossler_tx_j_sta_normal_ex_nocomment_sed.dat > ${dir}rossler_tx_j_sta_normal_ex_nocomment_one_sed.dat
    ./soukanzu ${dir}rossler_tx_j_sta_normal_ex_nocomment_one_sed.dat ${dir}pre_sta_normal_ex_nocomment_one.dat > ${dir}exex_sed.dat
    ./st ${dir}rossler_tx_j_sta_normal_ex_nocomment_one_sed.dat ${dir}pre_sta_normal_ex_nocomment_one.dat > ${dir}st_sed.dat
  done
#done
#done

#相関係数の平均を出す
#echo "///// cal mean /////"
#///// dirmean="./相関/mean/1/1_mean_$m"
#touch ./相関/mean/${j}/mean_corr.dat
#for p in  15 0 -15
#do
#  sum=0.000000000000
#  corr=0.000000000000
#  corr_sed=0.000000000000
#  for ((m=0 ; m<10 ; m++))
#  do
#    sed '/^#/d' ${dir}/st.dat > ${dirmean}/st_nocomment.dat
#    sed '/^#/d' ${dir}/st_sed.dat > ${dirmean}/st_sed_nocomment.dat
#    corr=`awk -F' ' '{print $1}' ${dirmean}/st_nocomment.dat`
#    corr_sed=`awk -F' ' '{print $1}' ${dirmean}/st_sed_nocomment.dat`
#    if [ $corr -gt $corr_sed ] ; then
#      sum=$(($sum + $corr))
#    else
#      sum=$(($sum + $corr_sed))
#    fi
#  done
#  $ans = $(($sum / 10))
#  echo $ans >> ./相関/mean/${j}/mean_corr.dat
#done

