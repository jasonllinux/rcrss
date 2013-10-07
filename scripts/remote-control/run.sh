#!/bin/bash

## Run 单张地图
#  Cluster
#   Map
#
#   Team 
#################

. $(dirname $0)/config.sh

CLUSTER=$1
MAP=$2
TEAM=$3
NAME=${TEAM_NAMES[$TEAM]}

SERVER=$(getServerHost $CLUSTER)


# 判断是否已经在run 了
eval $(ssh $REMOTE_USER@$SERVER cat $KERNELDIR/boot/$LOCKFILE_NAME 2>/dev/null)
if [ ! -z $RUNNING_TEAM ]; then
    echo "There is already a server running on cluster $CLUSTER"
    echo "${TEAM_NAMES[$RUNNING_TEAM]} ($RUNNING_TEAM) on $RUNNING_MAP"
    exit 1
fi;


# 开始
echo "Starting run for team $NAME ($TEAM) on map $MAP on cluster $CLUSTER."

# 预计算
#if [ -f "$CODEDIR/$TEAM/precompute.sh" ]; then
#    echo "Starting kernel for precomputation..."

#    ssh $REMOTE_USER@$SERVER $SCRIPTDIR/remoteStartKernelPrecompute.sh $MAP $TEAM&

#    sleep 6

#    for i in 1 2 3; do
#	CLIENT=$(getClientHost $CLUSTER $i)
#	ssh $REMOTE_USER@$CLIENT $SCRIPTDIR/remoteStartPrecompute.sh $TEAM $SERVER $i $MAP&
 #   done;

 #   sleep $PRECOMPUTE_TIMEOUT

  #  echo "stopping precomputation run"
 #  cancelRun.sh $CLUSTER
#fi


# 启动Server
echo "Starting kernel..."
#echo "Server host is $SERVER ...."
ssh $REMOTE_USER@$SERVER $SCRIPTDIR/remoteStartKernel.sh $MAP $TEAM&

sleep 8


#### 记录分数和截图
STATDIR=$LOCAL_HOMEDIR/$EVALDIR/$MAP/$TEAM
mkdir -p $STATDIR
cd /home/$REMOTE_USER/$KERNELDIR/boot
./extract-view.sh $NAME $SERVER $STATDIR&
cd $HOME


#### 启动Client
sleep 8
echo "running clents"
SERVER_IP=`resolveip -s  $SERVER`
echo "server ip $SERVER_IP"
for i in 1 2 3; do
	echo "client is: ............$CLIENT"
    CLIENT=$(getClientHost $CLUSTER $i)
    ssh $REMOTE_USER@$CLIENT $SCRIPTDIR/remoteStartAgents.sh $TEAM $SERVER_IP $i $MAP&
done;


### 等待结束
sleep 2

echo "Waiting fo run to finish..."

eval $(ssh $REMOTE_USER@$SERVER cat $KERNELDIR/boot/$LOCKFILE_NAME 2>/dev/null)
while [ ! -z $RUNNING_TEAM ]; do
    sleep 5
    unset RUNNING_TEAM
    eval $(ssh $REMOTE_USER@$SERVER cat $KERNELDIR/boot/$LOCKFILE_NAME 2>/dev/null)
done


#取消运行
sleep 2
echo "Stopping Run ..."
#cd /home/$REMOTE_USER/$KERNELDIR/boot/
cd  /home/$REMOTE_USER/roborescue/scripts/remote-control
bash ./cancelRun.sh $CLUSTER
echo "Stopped Run ..."

sleep 2
#生成html
echo "Evaluating run..."
cd  /home/$REMOTE_USER/roborescue/scripts/remote-control
bash ./evalRun.sh $CLUSTER
echo "Evaluated Run ..."
