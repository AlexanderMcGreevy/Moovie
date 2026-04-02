//
//  SliderQuestion.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/2/26.
//

import Foundation

struct SliderQuestion: Identifiable {
    let id: String
    let title: String
    let emojiStates: [EmojiState]
    let isUniversal: Bool

    func getEmoji(for value: Int) -> String {
        // Find the appropriate emoji based on value (0-100)
        for state in emojiStates {
            if value >= state.minValue && value <= state.maxValue {
                return state.emoji
            }
        }
        return emojiStates.first?.emoji ?? "❓"
    }
}

struct EmojiState {
    let emoji: String
    let minValue: Int
    let maxValue: Int
}

// MARK: - Universal Questions (5)

extension SliderQuestion {
    static let enjoyment = SliderQuestion(
        id: "enjoyment",
        title: "Overall Enjoyment",
        emojiStates: [
            EmojiState(emoji: "😴", minValue: 0, maxValue: 15),
            EmojiState(emoji: "😐", minValue: 16, maxValue: 30),
            EmojiState(emoji: "🙂", minValue: 31, maxValue: 50),
            EmojiState(emoji: "😊", minValue: 51, maxValue: 70),
            EmojiState(emoji: "😍", minValue: 71, maxValue: 85),
            EmojiState(emoji: "🤩", minValue: 86, maxValue: 95),
            EmojiState(emoji: "🏆", minValue: 96, maxValue: 100)
        ],
        isUniversal: true
    )

    static let story = SliderQuestion(
        id: "story",
        title: "Story/Plot",
        emojiStates: [
            EmojiState(emoji: "📱", minValue: 0, maxValue: 20),
            EmojiState(emoji: "📖", minValue: 21, maxValue: 40),
            EmojiState(emoji: "📚", minValue: 41, maxValue: 60),
            EmojiState(emoji: "🎭", minValue: 61, maxValue: 80),
            EmojiState(emoji: "🎬", minValue: 81, maxValue: 100)
        ],
        isUniversal: true
    )

    static let acting = SliderQuestion(
        id: "acting",
        title: "Acting/Performance",
        emojiStates: [
            EmojiState(emoji: "🤮", minValue: 0, maxValue: 20),
            EmojiState(emoji: "😐", minValue: 21, maxValue: 40),
            EmojiState(emoji: "🙂", minValue: 41, maxValue: 60),
            EmojiState(emoji: "👏", minValue: 61, maxValue: 80),
            EmojiState(emoji: "🎭", minValue: 81, maxValue: 100)
        ],
        isUniversal: true
    )

    static let soundtrack = SliderQuestion(
        id: "soundtrack",
        title: "Soundtrack",
        emojiStates: [
            EmojiState(emoji: "🔇", minValue: 0, maxValue: 20),
            EmojiState(emoji: "🔉", minValue: 21, maxValue: 40),
            EmojiState(emoji: "🎵", minValue: 41, maxValue: 60),
            EmojiState(emoji: "🎶", minValue: 61, maxValue: 80),
            EmojiState(emoji: "🎼", minValue: 81, maxValue: 100)
        ],
        isUniversal: true
    )

    static let rewatchability = SliderQuestion(
        id: "rewatchability",
        title: "Rewatchability",
        emojiStates: [
            EmojiState(emoji: "🥱", minValue: 0, maxValue: 20),
            EmojiState(emoji: "😐", minValue: 21, maxValue: 40),
            EmojiState(emoji: "🤔", minValue: 41, maxValue: 60),
            EmojiState(emoji: "😊", minValue: 61, maxValue: 80),
            EmojiState(emoji: "🔥", minValue: 81, maxValue: 100)
        ],
        isUniversal: true
    )

    static let universalQuestions: [SliderQuestion] = [
        .enjoyment,
        .story,
        .acting,
        .soundtrack,
        .rewatchability
    ]
}

// MARK: - Genre-Specific Questions

extension SliderQuestion {
    // Action (28)
    static let actionIntensity = SliderQuestion(
        id: "actionIntensity",
        title: "Action Intensity",
        emojiStates: [
            EmojiState(emoji: "😴", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🚶", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🏃", minValue: 51, maxValue: 75),
            EmojiState(emoji: "💥", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Comedy (35)
    static let funniness = SliderQuestion(
        id: "funniness",
        title: "Funniness",
        emojiStates: [
            EmojiState(emoji: "😐", minValue: 0, maxValue: 20),
            EmojiState(emoji: "🙂", minValue: 21, maxValue: 40),
            EmojiState(emoji: "😄", minValue: 41, maxValue: 60),
            EmojiState(emoji: "😂", minValue: 61, maxValue: 80),
            EmojiState(emoji: "🤣", minValue: 81, maxValue: 100)
        ],
        isUniversal: false
    )

    // Horror (27)
    static let scariness = SliderQuestion(
        id: "scariness",
        title: "Scariness",
        emojiStates: [
            EmojiState(emoji: "😴", minValue: 0, maxValue: 20),
            EmojiState(emoji: "😬", minValue: 21, maxValue: 40),
            EmojiState(emoji: "😰", minValue: 41, maxValue: 60),
            EmojiState(emoji: "😱", minValue: 61, maxValue: 80),
            EmojiState(emoji: "💀", minValue: 81, maxValue: 100)
        ],
        isUniversal: false
    )

    // Romance (10749)
    static let romanceLevel = SliderQuestion(
        id: "romanceLevel",
        title: "Romance Level",
        emojiStates: [
            EmojiState(emoji: "🙂", minValue: 0, maxValue: 25),
            EmojiState(emoji: "💕", minValue: 26, maxValue: 50),
            EmojiState(emoji: "💗", minValue: 51, maxValue: 75),
            EmojiState(emoji: "💖", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Sci-Fi (878)
    static let mindBending = SliderQuestion(
        id: "mindBending",
        title: "Mind-Bending",
        emojiStates: [
            EmojiState(emoji: "🤔", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🧐", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🤯", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🌌", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Thriller (53)
    static let suspense = SliderQuestion(
        id: "suspense",
        title: "Suspense",
        emojiStates: [
            EmojiState(emoji: "😌", minValue: 0, maxValue: 25),
            EmojiState(emoji: "😬", minValue: 26, maxValue: 50),
            EmojiState(emoji: "😰", minValue: 51, maxValue: 75),
            EmojiState(emoji: "😱", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Drama (18)
    static let emotionalDepth = SliderQuestion(
        id: "emotionalDepth",
        title: "Emotional Depth",
        emojiStates: [
            EmojiState(emoji: "😐", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🙁", minValue: 26, maxValue: 50),
            EmojiState(emoji: "😢", minValue: 51, maxValue: 75),
            EmojiState(emoji: "💔", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Animation (16)
    static let visualCreativity = SliderQuestion(
        id: "visualCreativity",
        title: "Visual Creativity",
        emojiStates: [
            EmojiState(emoji: "📱", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🎨", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🌈", minValue: 51, maxValue: 75),
            EmojiState(emoji: "✨", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Fantasy (14)
    static let worldBuilding = SliderQuestion(
        id: "worldBuilding",
        title: "World-Building",
        emojiStates: [
            EmojiState(emoji: "🏠", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🏰", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🪄", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🌟", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Crime (80) / Mystery (9648)
    static let mysteryIntrigue = SliderQuestion(
        id: "mysteryIntrigue",
        title: "Mystery/Intrigue",
        emojiStates: [
            EmojiState(emoji: "😴", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🤔", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🔍", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🕵️", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Documentary (99)
    static let educationalValue = SliderQuestion(
        id: "educationalValue",
        title: "Educational Value",
        emojiStates: [
            EmojiState(emoji: "📖", minValue: 0, maxValue: 25),
            EmojiState(emoji: "📚", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🎓", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🧠", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Adventure (12)
    static let adventureScale = SliderQuestion(
        id: "adventureScale",
        title: "Adventure Scale",
        emojiStates: [
            EmojiState(emoji: "🚶", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🏃", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🗺️", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🚀", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Music (10402)
    static let soundtrackQuality = SliderQuestion(
        id: "soundtrackQuality",
        title: "Musical Quality",
        emojiStates: [
            EmojiState(emoji: "🔇", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🎵", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🎶", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🎼", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // War (10752)
    static let warIntensity = SliderQuestion(
        id: "warIntensity",
        title: "War Intensity",
        emojiStates: [
            EmojiState(emoji: "😴", minValue: 0, maxValue: 25),
            EmojiState(emoji: "⚔️", minValue: 26, maxValue: 50),
            EmojiState(emoji: "💣", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🔥", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Western (37)
    static let westernVibes = SliderQuestion(
        id: "westernVibes",
        title: "Western Vibes",
        emojiStates: [
            EmojiState(emoji: "🏙️", minValue: 0, maxValue: 25),
            EmojiState(emoji: "🌾", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🤠", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🐎", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // History (36)
    static let historicalAccuracy = SliderQuestion(
        id: "historicalAccuracy",
        title: "Historical Feel",
        emojiStates: [
            EmojiState(emoji: "📖", minValue: 0, maxValue: 25),
            EmojiState(emoji: "📜", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🏛️", minValue: 51, maxValue: 75),
            EmojiState(emoji: "⏳", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Family (10751)
    static let familyFriendly = SliderQuestion(
        id: "familyFriendly",
        title: "Family-Friendly",
        emojiStates: [
            EmojiState(emoji: "😐", minValue: 0, maxValue: 25),
            EmojiState(emoji: "👨‍👩‍👧", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🎈", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🎉", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // TV Movie (10770)
    static let tvProduction = SliderQuestion(
        id: "tvProduction",
        title: "Production Quality",
        emojiStates: [
            EmojiState(emoji: "📹", minValue: 0, maxValue: 25),
            EmojiState(emoji: "📺", minValue: 26, maxValue: 50),
            EmojiState(emoji: "🎥", minValue: 51, maxValue: 75),
            EmojiState(emoji: "🎬", minValue: 76, maxValue: 100)
        ],
        isUniversal: false
    )

    // Genre mapping
    static func getGenreQuestions(for genreIds: [Int]) -> [SliderQuestion] {
        var questions: [SliderQuestion] = []

        for genreId in genreIds {
            switch genreId {
            case 28: questions.append(.actionIntensity)
            case 35: questions.append(.funniness)
            case 27: questions.append(.scariness)
            case 10749: questions.append(.romanceLevel)
            case 878: questions.append(.mindBending)
            case 53: questions.append(.suspense)
            case 18: questions.append(.emotionalDepth)
            case 16: questions.append(.visualCreativity)
            case 14: questions.append(.worldBuilding)
            case 80, 9648: questions.append(.mysteryIntrigue)
            case 99: questions.append(.educationalValue)
            case 12: questions.append(.adventureScale)
            case 10402: questions.append(.soundtrackQuality)
            case 10752: questions.append(.warIntensity)
            case 37: questions.append(.westernVibes)
            case 36: questions.append(.historicalAccuracy)
            case 10751: questions.append(.familyFriendly)
            case 10770: questions.append(.tvProduction)
            default: break
            }
        }

        // Remove duplicates (e.g., if both Crime and Mystery genres)
        return Array(Set(questions.map { $0.id })).compactMap { id in
            questions.first { $0.id == id }
        }
    }
}
