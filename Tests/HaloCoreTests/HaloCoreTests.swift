import XCTest
@testable import HaloCore

final class CatStateTests: XCTestCase {
    func testAllCasesCount() {
        XCTAssertEqual(CatState.allCases.count, 5)
    }

    func testAllCasesContainsExpectedStates() {
        let cases = Set(CatState.allCases)
        XCTAssertTrue(cases.contains(.idle))
        XCTAssertTrue(cases.contains(.walk))
        XCTAssertTrue(cases.contains(.sleep))
        XCTAssertTrue(cases.contains(.wantFish))
        XCTAssertTrue(cases.contains(.jump))
    }
}

final class SpriteDataTests: XCTestCase {
    // MARK: - Texture Name Counts

    func testIdleTextureCount() {
        XCTAssertEqual(SpriteData.idleTextureNames.count, 12)
    }

    func testWalkTextureCount() {
        XCTAssertEqual(SpriteData.walkTextureNames.count, 9)
    }

    func testSleepTextureCount() {
        XCTAssertEqual(SpriteData.sleepTextureNames.count, 4)
    }

    func testWantFishTextureCount() {
        XCTAssertEqual(SpriteData.wantFishTextureNames.count, 11)
    }

    func testJumpTextureCount() {
        XCTAssertEqual(SpriteData.jumpTextureNames.count, 18)
    }

    // MARK: - Texture Name Format

    func testIdleTextureNamesFormat() {
        XCTAssertEqual(SpriteData.idleTextureNames.first, "idle0")
        XCTAssertEqual(SpriteData.idleTextureNames.last, "idle11")
    }

    func testWalkTextureNamesFormat() {
        XCTAssertEqual(SpriteData.walkTextureNames.first, "walk0")
        XCTAssertEqual(SpriteData.walkTextureNames.last, "walk8")
    }

    func testSleepTextureNamesFormat() {
        XCTAssertEqual(SpriteData.sleepTextureNames.first, "sleep0")
        XCTAssertEqual(SpriteData.sleepTextureNames.last, "sleep3")
    }

    func testWantFishTextureNamesFormat() {
        XCTAssertEqual(SpriteData.wantFishTextureNames.first, "wantFish0")
        XCTAssertEqual(SpriteData.wantFishTextureNames.last, "wantFish10")
    }

    func testJumpTextureNamesFormat() {
        XCTAssertEqual(SpriteData.jumpTextureNames.first, "jump0")
        XCTAssertEqual(SpriteData.jumpTextureNames.last, "jump17")
    }

    // MARK: - Frame Rates

    func testFrameRatesDefinedForAllStates() {
        for state in CatState.allCases {
            XCTAssertNotNil(SpriteData.stateFrameRates[state],
                            "Missing frame rate for \(state)")
        }
    }

    func testFrameRatesArePositive() {
        for (state, rate) in SpriteData.stateFrameRates {
            XCTAssertGreaterThan(rate, 0, "Frame rate for \(state) must be positive")
        }
    }

    func testIdleAndWalkHaveSameFrameRate() {
        XCTAssertEqual(SpriteData.stateFrameRates[.idle],
                       SpriteData.stateFrameRates[.walk])
    }

    // MARK: - State Durations

    func testDurationsDefinedForAllStates() {
        for state in CatState.allCases {
            XCTAssertNotNil(SpriteData.stateDurations[state],
                            "Missing duration for \(state)")
        }
    }

    func testDurationsArePositive() {
        for (state, duration) in SpriteData.stateDurations {
            XCTAssertGreaterThan(duration, 0, "Duration for \(state) must be positive")
        }
    }

    func testJumpDurationIsShortest() {
        guard let jumpDuration = SpriteData.stateDurations[.jump] else {
            XCTFail("Missing jump duration"); return
        }
        for (state, duration) in SpriteData.stateDurations {
            if state != .jump {
                XCTAssertLessThan(jumpDuration, duration,
                                  "Jump should be shortest state")
            }
        }
    }

    func testSleepDurationIsLongest() {
        guard let sleepDuration = SpriteData.stateDurations[.sleep] else {
            XCTFail("Missing sleep duration"); return
        }
        for (state, duration) in SpriteData.stateDurations {
            if state != .sleep {
                XCTAssertGreaterThanOrEqual(sleepDuration, duration,
                                            "Sleep should be longest state")
            }
        }
    }

    // MARK: - Transition Weights

    func testTransitionWeightsSumToOne() {
        let sum = SpriteData.transitionWeights.values.reduce(0, +)
        XCTAssertEqual(sum, 1.0, accuracy: 0.001,
                       "Transition weights must sum to 1.0")
    }

    func testTransitionWeightsExcludeJump() {
        XCTAssertNil(SpriteData.transitionWeights[.jump],
                     "Jump should not be in random transitions")
    }

    func testTransitionWeightsCoverNonJumpStates() {
        let expected: Set<CatState> = [.idle, .walk, .sleep, .wantFish]
        let actual = Set(SpriteData.transitionWeights.keys)
        XCTAssertEqual(actual, expected)
    }

    func testAllWeightsArePositive() {
        for (state, weight) in SpriteData.transitionWeights {
            XCTAssertGreaterThan(weight, 0,
                                 "Weight for \(state) must be positive")
        }
    }
}
