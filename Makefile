ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DDForwardTimeLine

DDForwardTimeLine_FILES = DDForwardTimeLine.xm
DDForwardTimeLine_CFLAGS = -fobjc-arc
DDForwardTimeLine_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
