# AudioToolBox



此demo解决的问题，用audiounit实现播放音频

一、设置AVAudioSession，用来设置APP播放的行为，处理和其他APP音频播放的关系，以及中断处理

二、设置音频单元描述 Audiocomponentdescription。
struct AudioComponentDescription {
    OSType              componentType; //一个音频组件通用的独特的四字节码标识
    OSType              componentSubType;//
    OSType              componentManufacturer;
    UInt32              componentFlags;
    UInt32              componentFlagsMask;
}

1、使用 AudioComponentFindNext得到AudioComponent ：  AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputDesc);
2、最后调用AudioComponentInstanceNew(参数, &参数地址);得到audio的实例

三、初始化 AudioBufferList

用到的关键结构体
struct AudioBufferList
{
    UInt32      mNumberBuffers;// audiobuffer的数目
    AudioBuffer mBuffers[1]; // this is a variable length array of mNumberBuffers elements
}
//结构体 Audiobuffer
struct AudioBuffer
{
    UInt32              mNumberChannels;//声道数目
    UInt32              mDataByteSize;//是buffer的大小
    void* __nullable    mData;//音频数据的buffer
}
四、


//1、AudioUnitSetProperty 设置的这几个参数的含义
CF_ENUM(AudioUnitScope) {
kAudioUnitScope_Global        = 0,//设置回调函数
kAudioUnitScope_Input        = 1,
kAudioUnitScope_Output        = 2,//设置音频格式描述的时候
kAudioUnitScope_Group        = 3,
kAudioUnitScope_Part        = 4,
kAudioUnitScope_Note        = 5,
kAudioUnitScope_Layer        = 6,
kAudioUnitScope_LayerItem    = 7
};