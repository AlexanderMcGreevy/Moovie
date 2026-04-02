//
//  EmojiSlider.swift
//  Moovie
//
//  Created by Alexander McGreevy on 4/2/26.
//

import SwiftUI

struct EmojiSlider: View {
    let question: SliderQuestion
    @Binding var value: Int
    @State private var isDragging = false
    @State private var currentEmoji: String

    init(question: SliderQuestion, value: Binding<Int>) {
        self.question = question
        self._value = value
        let emoji = question.getEmoji(for: value.wrappedValue)
        self._currentEmoji = State(initialValue: emoji)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text(question.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemGray5))
                        .frame(height: 35)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    if !isDragging {
                                        isDragging = true
                                    }
                                    updateValue(for: gesture.location.x, width: geometry.size.width)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    triggerHaptic(.medium)
                                }
                        )

                    // Filled portion
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: calculateWidth(for: geometry.size.width), height: 35)
                        .allowsHitTesting(false)

                    // Emoji thumb
                    Text(currentEmoji)
                        .font(.system(size: 32))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                        .scaleEffect(isDragging ? 1.4 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
                        .offset(x: calculateThumbPosition(for: geometry.size.width))
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 44)

            
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func calculateWidth(for totalWidth: CGFloat) -> CGFloat {
        let percentage = CGFloat(value) / 100.0
        return max(22, totalWidth * percentage) // Min width to show emoji thumb
    }

    private func calculateThumbPosition(for totalWidth: CGFloat) -> CGFloat {
        let percentage = CGFloat(value) / 100.0
        return max(0, min(totalWidth - 44, totalWidth * percentage - 22))
    }

    private func updateValue(for x: CGFloat, width: CGFloat) {
        let percentage = max(0, min(1, x / width))
        let newValue = Int(percentage * 100)

        if newValue != value {
            value = newValue
            updateEmoji(for: newValue)
        }
    }

    private func updateEmoji(for newValue: Int) {
        let newEmoji = question.getEmoji(for: newValue)

        if newEmoji != currentEmoji {
            currentEmoji = newEmoji
            triggerHaptic(.light)
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview {
    VStack(spacing: 20) {
        EmojiSlider(question: .enjoyment, value: .constant(75))
        EmojiSlider(question: .scariness, value: .constant(50))
    }
    .padding()
}
