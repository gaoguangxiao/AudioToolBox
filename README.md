# AudioToolBox


//1、AudioUnitSetProperty 设置的这几个参数的含义
CF_ENUM(AudioUnitScope) {
kAudioUnitScope_Global        = 0,//
kAudioUnitScope_Input        = 1,
kAudioUnitScope_Output        = 2,
kAudioUnitScope_Group        = 3,
kAudioUnitScope_Part        = 4,
kAudioUnitScope_Note        = 5,
kAudioUnitScope_Layer        = 6,
kAudioUnitScope_LayerItem    = 7
};
