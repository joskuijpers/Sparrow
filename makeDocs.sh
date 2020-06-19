#!/bin/sh

rm -r ./Docs
mkdir Docs

cd SparrowEngine
jazzy --module SparrowEngine --swift-build-tool spm --output ../Docs/SparrowEngine
cd ..

cd SparrowECS
jazzy --module SparrowECS --swift-build-tool spm --output ../Docs/SparrowECS
cd ..

cd SparrowMesh
jazzy --module SparrowMesh --swift-build-tool spm --output ../Docs/SparrowMesh
cd ..

cd SparrowBinaryCoder
jazzy --module SparrowBinaryCoder --swift-build-tool spm --output ../Docs/SparrowBinaryCoder
cd ..

cd SparrowSafeBinaryCoder
jazzy --module SparrowSafeBinaryCoder --swift-build-tool spm --output ../Docs/SparrowSafeBinaryCoder
cd ..
