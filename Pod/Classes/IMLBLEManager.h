//
//  CYBluetoothPeripheralManager.h
//  UniversalArchitecture
//
//  Created by chewyong on 15/12/24.
//  Copyright © 2015年 zhangli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface  IMLBLEManager : NSObject

//当前连接的外设
@property(nonatomic,retain)CBPeripheral *connectedPeriphearl;
//发现的外设
@property (strong, nonatomic) NSMutableArray *foundPeripherals;


+ (id)sharedInstance;


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
                                failed:(void (^)(NSString *))failed;


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
                                   failed:(void (^)(NSString *))failed;

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
                     failed:(void (^)(NSString *))failed;

/*!
 *  @method cancelConnectWithPeripheral:
 *
 *  @param peripheral  要断开的外设
 *
 *  @discussion  断开连接
 */

- (void)cancelConnectWithPeripheral:(CBPeripheral *)peripheral;

@end
