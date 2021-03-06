# Copyright 2015 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := motive
LOCAL_ARM_MODE := arm
LOCAL_STATIC_LIBRARIES := libmathfu cpufeatures

MOTIVE_RELATIVE_DIR := ..
MOTIVE_DIR := $(LOCAL_PATH)/$(MOTIVE_RELATIVE_DIR)

include $(MOTIVE_DIR)/jni/android_config.mk
include $(DEPENDENCIES_FLATBUFFERS_DIR)/android/jni/include.mk

LOCAL_EXPORT_C_INCLUDES := \
  $(MOTIVE_DIR)/include \
  $(MOTIVE_GENERATED_OUTPUT_DIR) \
  $(DEPENDENCIES_MATHFU_DIR)/benchmarks

LOCAL_C_INCLUDES := \
  $(LOCAL_EXPORT_C_INCLUDES) \
  $(MOTIVE_DIR)/src \
  $(DEPENDENCIES_FLATBUFFERS_DIR)/include \
  $(DEPENDENCIES_FPLUTIL_DIR)/libfplutil/include

LOCAL_SRC_FILES := \
  $(MOTIVE_RELATIVE_DIR)/src/engine.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/io/flatbuffers.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/math/bulk_spline_evaluator.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/math/compact_spline.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/math/curve.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/math/dual_cubic.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/motivator.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/processor/matrix_processor.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/processor/overshoot_processor.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/processor/smooth_processor.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/processor.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/util/benchmark.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/util/optimizations.cpp \
  $(MOTIVE_RELATIVE_DIR)/src/version.cpp

MOTIVE_ENABLE_BENCHMARKING ?= 0
ifneq ($(MOTIVE_ENABLE_BENCHMARKING),0)
  LOCAL_CFLAGS += -DBENCHMARK_MOTIVE
endif

MOTIVE_ENABLE_ASSEMBLY ?= 1
MOTIVE_TEST_ASSEMBLY ?= 0
ifneq ($(MOTIVE_ENABLE_ASSEMBLY),0)
  # Presently, we only have assembly functions for 'armeabi-v7a' and
  # 'armeabi-v7a-hard'.
  ifneq (,$(findstring armeabi-v7a,$(TARGET_ARCH_ABI)))
    # Use the .neon extension to compile with NEON support.
    LOCAL_SRC_FILES += \
      $(MOTIVE_RELATIVE_DIR)/src/math/bulk_spline_evaluator_neon.s.neon
    LOCAL_CFLAGS += -DMOTIVE_NEON

    # Run both NEON and C++ code and compare results.
    ifneq ($(MOTIVE_TEST_ASSEMBLY),0)
      LOCAL_CFLAGS += -DMOTIVE_ASSEMBLY_TEST=Neon
    endif
  endif
endif

MOTIVE_SCHEMA_DIR := $(MOTIVE_DIR)/schemas
MOTIVE_SCHEMA_INCLUDE_DIRS :=

MOTIVE_SCHEMA_FILES := \
  $(MOTIVE_SCHEMA_DIR)/motive.fbs

ifeq (,$(MOTIVE_RUN_ONCE))
MOTIVE_RUN_ONCE := 1
$(call flatbuffers_header_build_rules, \
  $(MOTIVE_SCHEMA_FILES), \
  $(MOTIVE_SCHEMA_DIR), \
  $(MOTIVE_GENERATED_OUTPUT_DIR), \
  $(MOTIVE_SCHEMA_INCLUDE_DIRS), \
  $(LOCAL_SRC_FILES))
endif

include $(BUILD_STATIC_LIBRARY)

$(call import-add-path,$(DEPENDENCIES_FLATBUFFERS_DIR)/..)
$(call import-add-path,$(DEPENDENCIES_MATHFU_DIR)/..)

$(call import-module,flatbuffers/android/jni)
$(call import-module,mathfu/jni)
$(call import-module,android/cpufeatures)
