//
//  ViewController.m
//  AudioToolPlayer
//
//  Created by gaoguangxiao on 2018/8/10.
//  Copyright © 2018年 gaoguangxiao. All rights reserved.
//

#import "ViewController.h"
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
//#import <assert.h>

#define kInputBus (1)
#define kOutputBus (0)

#define CONST_BUFFER_SIZE (0x10000)
static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

@interface ViewController ()
{
    AudioUnit audioUnit;
    
    AudioBufferList *_bufferList;
    AudioStreamBasicDescription _outputFormat;
    ExtAudioFileRef _audioFile;
    
    UInt64 _totalFrame;
    UInt64 _readedFrame;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    

    //2、判断是否能打开
//    AudioFileID audioFileId;
//    OSStatus status = AudioFileOpenURL((__bridge CFURLRef _Nonnull)(url), kAudioFileReadPermission, 0, &audioFileId);
//    if (status != noErr) {
//        NSLog(@"文件读取失败");
//    }

    
    
    


    //开始
    [self initAudioUnitWithRate:44100 bit:16 channel:1];
    
    
    // 初始化
    //    status = AudioUnitInitialize(audioUnit);
    //    CheckError(status,"nih");
    
}
- (IBAction)PlayerMusic:(UIButton *)sender {
    
    if (sender.tag == 0) {
        OSStatus status = AudioOutputUnitStart(audioUnit);
        CheckError(status,"playr failure");
    }else{
        OSStatus status = AudioOutputUnitStop(audioUnit);
        CheckError(status,"stop failure");
    }
}


- (void)initAudioUnitWithRate:(Float64)rate bit:(UInt32)bit channel:(UInt32)channel
{
    //1、设置session
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [session setActive:YES error:nil];
    
    //2、初始化audioUnit描述音频文件
    AudioComponentDescription outputDesc = [self allocAudioComponentDescriptionWithComponentType:kAudioUnitType_Output componentSubType:kAudioUnitSubType_VoiceProcessingIO componentFlags:0 componentFlagsMask:0];
    
    //使用AudioComponentFindNext获取AudioComponentDescription
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputDesc);
    
    //获取audio的实例
    AudioComponentInstanceNew(outputComponent, &audioUnit);
    

    

    //3、初始化 AudioBufferList
    _bufferList = [self allocAudioBufferListWithMDataByteSize:CONST_BUFFER_SIZE mNumberChannels:1 mNumberBuffers:1];
    
    //4、设置输出格式
    int mFramesPerPacket = 1;
    //描述音频格式
    _outputFormat = [self allocAudioStreamBasicDescriptionWithMFormatID:kAudioFormatLinearPCM mFormatFlags:(kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved) mSampleRate:rate mFramesPerPacket:mFramesPerPacket mChannelsPerFrame:channel mBitsPerChannel:bit];
    
    AudioUnitInitialize(audioUnit);
    //5、应用播放的音频格式描述
    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           kOutputBus,
                                           &_outputFormat,
                                           sizeof(_outputFormat));
    CheckError(status, "SetProperty StreamFormat failure");
    
    //6、设置声音输出回调函数，当speraker需要数据就会调用 回调函数去获取数据，是拉数据的概念
    AURenderCallbackStruct outputCallBackStruct;
    outputCallBackStruct.inputProc = outputCallBackFun;
    outputCallBackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &outputCallBackStruct,
                                  sizeof(outputCallBackStruct));
    CheckError(status, "SetProperty EnableIO failure");
    
    //7、录入需要播放的文件
    //ExtAudioFile是high_level的API，提供音频的读写，是Audio File和audio conerter的结合
    
    NSString *musicPath = [[NSBundle mainBundle]pathForResource:@"几个你_薛之谦" ofType:@"aac"];
    NSURL *url = [NSURL fileURLWithPath:musicPath];
    CheckError(ExtAudioFileOpenURL((__bridge CFURLRef)url, &_audioFile),"打开文件失败");//新建一个 ExAudioFileRef，用于读取音频文件
    uint size = sizeof(_outputFormat);
    
    CheckError(ExtAudioFileSetProperty(_audioFile,
                                       kExtAudioFileProperty_ClientDataFormat,
                                       size,
                                       &_outputFormat), "setkExtAudioFileProperty_ClientDataFormat failure");
    
    size = sizeof(_totalFrame);
    //    ExtAudioFileGetProperty 文件的长度，单位是sample frames，获取前需要先设置好输入和输出的格式；
    CheckError(ExtAudioFileGetProperty(_audioFile,
                                       kExtAudioFileProperty_FileLengthFrames,
                                       &size,
                                       &_totalFrame), "获取总帧数失败");
    _readedFrame = 0;

}
- (AudioStreamBasicDescription)allocAudioStreamBasicDescriptionWithMFormatID:(AudioFormatID)mFormatID mFormatFlags:(AudioFormatFlags)mFormatFlags mSampleRate:(NSInteger )mSampleRate  mFramesPerPacket:(UInt32)mFramesPerPacket mChannelsPerFrame:(UInt32)mChannelsPerFrame mBitsPerChannel:(UInt32)mBitsPerChannel
{
    AudioStreamBasicDescription _outputFormat;
    memset(&_outputFormat, 0, sizeof(_outputFormat));
    _outputFormat.mSampleRate       = mSampleRate;
    _outputFormat.mFormatID         = mFormatID;
    _outputFormat.mFormatFlags      = mFormatFlags;
    _outputFormat.mFramesPerPacket  = mFramesPerPacket;
    _outputFormat.mChannelsPerFrame = mChannelsPerFrame;
    _outputFormat.mBitsPerChannel   = mBitsPerChannel;//采样精度
    _outputFormat.mBytesPerFrame    = mBitsPerChannel * mChannelsPerFrame / 8;//每帧的字节数 16 * 2 /8
    _outputFormat.mBytesPerPacket   = mBitsPerChannel * mChannelsPerFrame / 8 * mFramesPerPacket;
    return _outputFormat;
}

//创建AudioBufferList
- (AudioBufferList *)allocAudioBufferListWithMDataByteSize:(UInt32)mDataByteSize mNumberChannels:(UInt32)mNumberChannels mNumberBuffers:(UInt32)mNumberBuffers
{
    AudioBufferList *_bufferList;
    _bufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    _bufferList->mNumberBuffers = mNumberBuffers;
    _bufferList->mBuffers[0].mData = malloc(mDataByteSize);
    _bufferList->mBuffers[0].mDataByteSize = mDataByteSize;
    _bufferList->mBuffers[0].mNumberChannels = mNumberChannels;
    return _bufferList;
}
/**
 componentType : kAudioUnitType_
 componentSubType : kAudioUnitSubType_
 componentFlags : 0
 componentFlagsMask : 0
 */
- (AudioComponentDescription)allocAudioComponentDescriptionWithComponentType:(OSType)componentType componentSubType:(OSType)componentSubType componentFlags:(UInt32)componentFlags componentFlagsMask:(UInt32)componentFlagsMask
{
    AudioComponentDescription outputDesc;
    outputDesc.componentType = componentType;
    outputDesc.componentSubType = componentSubType;
    outputDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDesc.componentFlags = componentFlags;
    outputDesc.componentFlagsMask = componentFlagsMask;
    return outputDesc;
}
- (void)stop
{
//    self.bl_input = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stop];
//        _player = nil;
    });
}

//播放回调函数
static OSStatus outputCallBackFun(void *                            inRefCon,
                                  AudioUnitRenderActionFlags *    ioActionFlags,
                                  const AudioTimeStamp *            inTimeStamp,
                                  UInt32                            inBusNumber,
                                  UInt32                            inNumberFrames,
                                  AudioBufferList * __nullable    ioData)
{
    
    memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    
    ViewController *strongSelf = (__bridge ViewController *)(inRefCon);
    __weak typeof(strongSelf) weakSelf = strongSelf;

    strongSelf->_bufferList->mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
    OSStatus status = ExtAudioFileRead(strongSelf->_audioFile, &inNumberFrames, strongSelf->_bufferList);
   //把资源内存拷贝到目标内存
    memcpy(ioData->mBuffers[0].mData, strongSelf->_bufferList->mBuffers[0].mData, strongSelf->_bufferList->mBuffers[0].mDataByteSize);
    ioData->mBuffers[0].mDataByteSize = strongSelf->_bufferList->mBuffers[0].mDataByteSize;

    if (ioData->mBuffers[0].mDataByteSize == 0){
        [weakSelf stop];
    }
    strongSelf->_readedFrame += ioData->mBuffers[0].mDataByteSize / strongSelf->_outputFormat.mBytesPerFrame;
    
    CheckError(status, "转换格式失败");
    if (inNumberFrames == 0) NSLog(@"播放结束");
    NSLog(@"%f",[strongSelf getProgress]);
    
    
    return noErr;
}
- (float)getProgress{
    return _readedFrame * 1.0 / _totalFrame;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
