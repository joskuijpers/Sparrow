#!/bin/sh

rm -r ./Docs
mkdir Docs

cd SparrowEngine2
jazzy --module SparrowEngine2 --swift-build-tool spm --output ../Docs/SparrowEngine2
cd ..

cd SparrowECS
jazzy --module SparrowECS --swift-build-tool spm --output ../Docs/SparrowECS
cd ..

cd SparrowAsset
jazzy --module SparrowAsset --swift-build-tool spm --output ../Docs/SparrowAsset
cd ..

cd SparrowBinaryCoder
jazzy --module SparrowBinaryCoder --swift-build-tool spm --output ../Docs/SparrowBinaryCoder
cd ..

cd SparrowSafeBinaryCoder
jazzy --module SparrowSafeBinaryCoder --swift-build-tool spm --output ../Docs/SparrowSafeBinaryCoder
cd ..
