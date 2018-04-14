/*
 0.导入框架
 1.建立中央管理者
 2.扫描周边设备
 3.链接扫描到的设备
 4.扫描服务
 5.扫描特征
 6.根据需求进行数据的一个处理
 
*/

/**
 core BlueTooth  通过第三方来传输，但是测试比较麻烦，正常情况下，至少得2台真是的蓝牙4.0设备
 使用场景: 运动手环，只能家具 嵌入式设备(金融刷卡器，新店测量器)
 评估板也就30-70RMB
 
 
 */
#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager; /**< 中央管理者 */
@property (nonatomic, strong) NSMutableArray *peripheralArray;; /**< 扫描到的外设 */
@end

@implementation ViewController
//懒加载
- (NSMutableArray *)peripheralArray {
    if (_peripheralArray == nil) {
        _peripheralArray = [NSMutableArray array];
    }
    return _peripheralArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 1.建立中央管理者
    // queue:传空,代表的就是在主队列
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    //2.扫描周边设备
    // Services:服务的UUID,是一个数据.如果传nil,默认就会扫描全部所有的服务
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}
/***
 
 CBManagerStateUnknown = 0,  未知
 CBManagerStateResetting,   重置
 CBManagerStateUnsupported, 不支持
 CBManagerStateUnauthorized, 未经授权
 CBManagerStatePoweredOff, 没有启动
 CBManagerStatePoweredOn 开启
 */
#pragma mark - CBCentralManager代理方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"state: %ld",(long)central.state);//状态为2代表不支持
    if(central.state == CBManagerStateUnknown){
         NSLog(@"未知蓝牙");
    }if(central.state == CBManagerStatePoweredOn){
        //2扫描外设
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
}

/**
 当发现外围设备时,会调用这个方法

 @param central 控制中心
 @param peripheral 外围设备
 @param advertisementData 相关数据
 @param RSSI 信号的强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI {
    // 3.记录扫描到的设备
    if (![self.peripheralArray containsObject:peripheral]) {
        [self.peripheralArray addObject:peripheral];
    }
    // 伪步骤.用一个列表显示咋们检测到的外设备.
    
    // 4.连接扫描到的设备
    [self.centralManager connectPeripheral:peripheral options:nil];
    
    // 5.设置外围设备的一个代理
    peripheral.delegate = self;
    
}

#pragma mark - 连接到设备之后,会调这方法
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    //    6.扫描服务nil代表扫描所有服务
    [peripheral discoverServices:nil];
}

#pragma mark - 外设的代理方法.当发现到读物的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    // 7. 获取制定的服务,根据这个服务来查找特征
    //services:外设的所有服务,会保存在一个servicse中
    for (CBService *service in peripheral.services) {
        // 判断设备UUID是否一致
        if ([service.UUID.UUIDString isEqualToString:@"123"]) {
            // UUID一直的话,就开始扫描
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
// 当发现特征时回调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error {

    //    8.获取制定特征
    for (CBCharacteristic *characteristic in service.characteristics)
    {
      //
        if ([characteristic.UUID.UUIDString isEqualToString:@"789"]) {
            //    9.根据需求进行数据的一个处理
            // 如果获取到了指定的特征,就可以进行数据交换了
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

#pragma mark - 断开
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // 10.最后断开连接
    [self.centralManager stopScan];
}

@end
