# luci-app-ssr-plus-jo

## 说明
   源码来源：https://github.com/coolsnowwolf
   
1.免开门

2.增加图标检查

3.增加ping延迟

4.udp2raw/UDPspeeder 支持

## 使用方法
```Brach
    #源码根目录，进入package文件夹
    cd package
    #下载源码
    git clone https://github.com/Ameykyl/luci-app-ssr-plus-jo
    #回到源码根目录
    cd ..
    make menuconfig
    #编译
    make package/luci-app-ssr-plus-jo/{clean,compile} V=s
