#!/bin/sh

cd SparrowBinaryCoder
jazzy --module SparrowBinaryCoder --swift-build-tool spm --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
cd ..

cd SparrowSafeBinaryCoder
jazzy --module SparrowSafeBinaryCoder --swift-build-tool spm --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
cd ..
