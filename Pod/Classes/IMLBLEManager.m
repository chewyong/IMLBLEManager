//
//  CYBluetoothPeripheralManager.m
//  UniversalArchitecture
//
//  Created by chewyong on 15/12/24.
//  Copyright © 2015年 zhangli. All rights reserved.
//

#import "IMLBLEManager.h"

//当前外设的状态
typedef enum tag_CBCentral_Mode
{
    CBCENTRAL_NULL = 0,
    CBCENTRAL_SCAN,
    CBCENTRAL_CONNECT,
    CBCENTRAL_ISSUE
}CBCENTRAL_MODE;


typedef void(^ScanCompletion)(NSArray *);
typedef void(^ScanFailed)(NSString*);
typedef void(^ConnectCompletion)(BOOL);
typedef void(^ConnectFailed)(NSString *);
typedef void(^DisconneCompletion)(BOOL);
typedef void(^IssueCommandCompletion)(NSString*);
typedef void(^IssueCommandFailed)(NSString*);

@interface IMLBLEManager()<CBCentralManagerDelegate,CBPeripheralDelegate> {
    //是否主动断开连接
    BOOL isManualCancelConnect;
}

@property (copy, nonatomic) ScanCompletion scanCompletion;
@property (copy, nonatomic) ScanFailed scanFailed;
@property (copy, nonatomic) ConnectCompletion connectCompletion;
@property (copy, nonatomic) ConnectFailed connectFailed;
@property (copy, nonatomic) DisconneCompletion disconneCompletion;
@property (copy, nonatomic) IssueCommandCompletion issueCommandCompletion;
@property (copy, nonatomic) IssueCommandFailed issueCommandFailed;

//蓝牙设备状态
@property (assign, nonatomic) CBCENTRAL_MODE centralMode;
//蓝牙中心管理器
@property (strong, nonatomic) CBCentralManager *centralManager;
//超时计时器
@property (strong, nonatomic) NSTimer *timer;
//外设服务id数组
@property (strong, nonatomic) NSArray *serviceUUIDs;
//服务特征ID数组
@property (strong, nonatomic) NSMutableArray *characteristicUUIDs;
//当前发指令的服务特征值id
@property (strong, nonatomic) NSString *characteristicUUID;

@end

@implementation IMLBLEManager


static IMLBLEManager *BLESharedInstance = nil;


+ (id)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BLESharedInstance = [[IMLBLEManager alloc] init];
    });
    
    return BLESharedInstance;
}

- (id)init
{
    self = [super init];
    if (self){
        [self customInit];
    }
    return self;
}

#pragma mark - private

- (void)customInit{
    _foundPeripherals = [[NSMutableArray alloc] initWithCapacity:0];
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)startTimerWithPeripheralType:(CBCENTRAL_MODE)type{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    self.centralMode = type;
    self.timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(timeOutAction) userInfo:nil repeats:NO];
}

- (void)stopTimer{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    self.centralMode = CBCENTRAL_NULL;
}

- (void)timeOutAction{
    [self stopTimer];
    switch (_centralMode) {
        case CBCENTRAL_SCAN:
        {
            if (_scanFailed) {
                _scanFailed(@"搜索超时");
            }
        }
            break;
        case CBCENTRAL_CONNECT:
        {
            if (_scanFailed) {
                _connectFailed(@"连接超时");
            }
        }
            break;
        case CBCENTRAL_ISSUE:
        {
            if (_scanFailed) {
                _issueCommandFailed(@"获取数据超时");
            }
        }
            break;

        default:
            break;
    }
}


- (void)setServiceUUIDs:(NSArray *)serviceUUIDs{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *idStr in serviceUUIDs) {
        [array addObject:[CBUUID UUIDWithString:idStr]];
    }
    _serviceUUIDs = array;
}


/*!
 *  @method comparePeripheralisEqual
 *
 *  @param discoverPeripheral   发现的外设
 *  @return 新的外设返回NO
 *  @discussion  判断一个外设是否是新发现的
 */
- (BOOL)comparePeripheralisEqual:(CBPeripheral *)discoverPeripheral
{
    if ([_foundPeripherals count]>0) {
        for (int i=0;i<[_foundPeripherals count]; i++) {
            CBPeripheral *blePer = [_foundPeripherals objectAtIndex:i];
            if ([discoverPeripheral isEqual:blePer]) {
                
                return YES;
            }
        }
    }
    return NO;
}

/*!
 *  @method isTagetPeripheral
 *
 *  @param uuids   外设服务特征值数组
 *  @return 是指定特征值的外设返回YES,没有指定特征值返回YES
 *  @discussion  判断一个外设是否是指定特征值的外设或没有指定特征值的外设
 */
- (BOOL)isTagetPeripheralWithUUIDs:(NSArray *)uuids{
    if (_serviceUUIDs == nil || [_serviceUUIDs count]==0) {
        return YES;
    }
    BOOL isTagetPeri = NO;
    for (CBUUID *uuid in uuids) {
        for (CBUUID *serviceUUID in _serviceUUIDs) {
            if ([uuid isEqual:serviceUUID]) {
                isTagetPeri = YES;
                break;
            }
        }
    }

    return isTagetPeri;
}



#pragma mark - search peripherals

/*!
 *  @method connectPeripheralWithCBPeripheral:completion:failed
 *
 *  @param uuids  外设的服务uuid数组
 *  @param completion  扫描到设备时回调，如果扫描到多个设备回调多次
 *  @param failed  扫描失败回调(扫描超时回调)
 *  @discussion  根据外设的服务uuid扫描当前环境中的外设，uuids为空时返回所有
 */

- (void)scanPeripheralWithServiceUUIDs:(NSArray*)uuids
                    completion:(void(^)(NSArray *))completion
                        failed:(void (^)(NSString *))failed{
    
    self.serviceUUIDs = uuids;
    _scanCompletion = completion;
    _scanFailed = failed;
    [self startTimerWithPeripheralType:CBCENTRAL_SCAN];
    [self performSelector:@selector(scanForPeripheral) withObject:nil afterDelay:0.1];
}

- (void)scanForPeripheral{
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
}


/*!
 *  @method connectPeripheralWithCBPeripheral:completion:failed
 *
 *  @param peripheral  要连接的外设
 *  @param completion  连接成功回调
 *  @param failed  连接失败回调
 *  @discussion  连接到蓝牙设备
 */
- (void)connectPeripheralWithCBPeripheral:(CBPeripheral *)peripheral
                               completion:(void (^)(BOOL connected))completion
                                   failed:(void (^)(NSString *))failed{
    _connectCompletion = completion;
    _connectFailed = failed;
    if (peripheral)
    {
        //开启计时器
        [self startTimerWithPeripheralType:CBCENTRAL_CONNECT];
        //连接蓝牙设备
        [self connect:peripheral];
        //停止扫描蓝牙
        [self.centralManager stopScan];
    }
}

/*!
 *  @method connect
 *
 *  @param peripheral   连接到的外设
 *  @discussion  与指定外设连接
 */
-(BOOL)connect:(CBPeripheral *)peripheral{
    isManualCancelConnect = NO;
    if (self.characteristicUUIDs) {
        [self.characteristicUUIDs removeAllObjects];
    }else{
        self.characteristicUUIDs = [[NSMutableArray alloc] init];
    }
    self.centralManager.delegate = self;
    [self.centralManager connectPeripheral:peripheral
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    return YES;
}

/*!
 *  @method issuingWithCommand:uuids:completion:failed
 *
 *  @param data  要发送到外设的数据
 *  @param uuid  接收数据的特征uuid
 *  @param completion  发送完成回调
 *  @param failed  发送失败回调
 *  @discussion  开始发送指令
 */

-(void)issueCommandWtihData:(NSData *)data
         characteristicUUID:(NSString*)uuid
                 completion:(void(^)(NSString *))completion
                     failed:(void (^)(NSString *))failed{
    _issueCommandCompletion = completion;
    _issueCommandFailed = failed;
    self.characteristicUUID = uuid;
    CBCharacteristic *characteristic;
    for (CBCharacteristic *chara in _characteristicUUIDs) {
        if ([[chara.UUID UUIDString] isEqualToString:self.characteristicUUID]) {
            characteristic = chara;
            break;
        }
    }
    if (characteristic) {
        [self startTimerWithPeripheralType:CBCENTRAL_ISSUE];
        [self.connectedPeriphearl writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        _issueCommandFailed(@"无效的特征值");
    }
    
}


/*!
 *  @method cancelConnectWithPeripheral:
 *
 *  @param peripheral  要断开的外设
 *
 *  @discussion  断开连接
 */

- (void)cancelConnectWithPeripheral:(CBPeripheral *)peripheral{
    isManualCancelConnect = YES;
    [self.centralManager cancelPeripheralConnection:peripheral];
}



#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"peripheral : %@",peripheral);
    NSLog(@"peripheral data : %@",advertisementData);
    NSArray *uuids = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    [_foundPeripherals removeAllObjects];
    //是否指定特征值的外设 && 是否新发现的外设
    if ([self isTagetPeripheralWithUUIDs:uuids] && ![self comparePeripheralisEqual:peripheral]) {
        //[self stopTimer];
        [_foundPeripherals addObject:peripheral];
        _scanCompletion(_foundPeripherals);
    }
}

//连接到蓝牙设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    self.connectedPeriphearl = peripheral;
    NSLog(@"连接成功");
    [self.connectedPeriphearl setDelegate:self];
    [self.connectedPeriphearl discoverServices:nil];
    if (_connectCompletion) {
        _connectCompletion(YES);
    }
}

//连接蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接失败");
    if (_connectFailed) {
        _connectFailed(@"连接失败");
    }
}

//与蓝牙设备断开
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"断开连接");
    self.connectedPeriphearl = nil;
    if (isManualCancelConnect && _disconneCompletion) {
        //人为断开连接
        _disconneCompletion(YES);
    }
}


#pragma mark - CBPeripheralDelegate

//发现外设的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    for (CBService *service in peripheral.services){
        NSLog(@"Service found with UUID: %@", service.UUID);
        //发现服务
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

//发现服务的特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"Discovered characteristics for %@", characteristic.UUID);
        [self.characteristicUUIDs addObject:characteristic];
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

//获取到外设的数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
{
    NSString *data = [NSString stringWithFormat:@"%@",characteristic.value];

    _issueCommandCompletion(data);
}


@end
