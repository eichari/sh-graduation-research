#距離行列を一つ読み込ませて古典的多次元尺度法を適応する

args = commandArgs(trailingOnly=TRUE) ##データの名前を引数として読みこむ
file_name <- as.character(args[1])
#file_name2 <- as.character(args[2])

# message(paste("file_name = ", file_name, sep=""))#引数を読み込めているか確認
# message(paste("file_name = ", file_name2, sep=""))#引数を読み込めているか確認

data <- read.table(file_name, header=F) ##データ読み込み,1行目indexなし
result <- cmdscale(data, k=1)#古典的多次元尺度法
# write.table(result, file="./neuron_n150_time75_theta01/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="./neuron3_noise/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="./roji_CMDS/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="./ten_neuron/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="./相関/0925/k05/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
## write.table(result, file="./相関/0925/0-t-4省いて入力の極値を1つとらない/plus/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
## write.table(result, file="./相関/0925/0-t-4省かず入力の極値を1つとらない/minus/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

# write.table(result, file="./相関/0926/LIF/1個ノイズなしk=0.3/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="./相関/0926/追試/距離行列以降/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="../2020-10/1013/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="../2020-10/1013/sin/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
# write.table(result, file="../2020-10/1015/8周期解/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

#write.table(result, file="../2020-10/1017/sin10/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
#write.table(result, file="./2020-10/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
#result

#write.table(result, file="../2020-10/1023/sin/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
#write.table(result, file="../2020-10/1022/theta_1.0/pre_x.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
#write.table(result, file="../2020-11/1113-4/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

#write.table(result, file="../2020-11/1120-500-half/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
#write.table(result, file="../2020-11/1124/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

#write.table(result, file="pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

#write.table(result, file="../2020-12/1218/k=1.0/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
#write.table(result, file="../2020-12/1219/k=1.0bias=40time=250/pre.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

#write.table(result, file="../2020-12/1222/atractor_time100/pre2.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力
write.table(result, file="../2020-12/1218/ISIの変化の確認/pre2.dat", sep=" ", quote=F, col.names=F, append=T)#結果出力

