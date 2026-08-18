//
//  QuestionCardView.swift
//  POC
//
//  Created by Asaryun on 18/08/26.
//

import SwiftUI

struct QuestionCardView: View {
    let onPlayAgain: () -> Void
    let onBackToMenu: () -> Void

    @State private var selectedAnswer: Answer?
    @State private var answered = false

    enum Answer {
        case ultrasonic
        case flashlight
    }

    private let question =
        "What did you use to find the mangoes last night?"

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.15)
                .ignoresSafeArea()

            if answered {
                resultView
            } else {
                questionView
            }
        }
        .transition(.opacity)
    }

    // MARK: - Question

    private var questionView: some View {
        ZStack {
            Image("quiz-card-bg")
                .resizable()
                .aspectRatio(
                    379.0 / 439.0,
                    contentMode: .fit
                )
                .frame(width: 330)
//                .scaleEffect(1.2)

            VStack(spacing: 14) {
                Text(question)
                    .font(
                        .system(
                            size: 17,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                    .frame(width: 245)

                VStack(spacing: 8) {
                    answerButton(
                        title: "A. ULTRASONIC",
                        answer: .ultrasonic
                    )

                    answerButton(
                        title: "B. FLASHLIGHT",
                        answer: .flashlight
                    )
                }
            }
            .frame(
                width: 330,
                height: 380,
                alignment: .center
            )
        }
    }

    // MARK: - Answer Button

    private func answerButton(
        title: String,
        answer: Answer
    ) -> some View {
        Button {
            select(answer)
        } label: {
            ZStack {
                Image("filled-button-border")
                    .resizable()
                    .aspectRatio(
                        contentMode: .fit
                    )
                    .frame(width: 145)

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Result View

        private var isCorrect: Bool {
            selectedAnswer == .ultrasonic
        }

        private var resultView: some View {
            VStack(spacing: 16) {
                // Main Top Result Card
                ZStack(alignment: .top) {
                    Image(isCorrect ? "correct-quiz-card" : "incorrect-quiz-card")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 320)

                    VStack(spacing: 8) {
                        if isCorrect {
                            Text("A. ULTRASONIC")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 0.15, green: 0.2, blue: 0.45))

                            Text("You are super smart! You used your superpower perfectly.")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.black)
                                .frame(width: 220)
                                .lineSpacing(3)
                        } else {
                            Text("That's not it. Remember the bouncy sound we used? Try again!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.black)
                                .frame(width: 210)
                                .lineSpacing(3)
//                                .padding(.top, 16)
                        }
                    }
                    .padding(.top, 120) // Offsets text safely below the header banner
                }

                // Bottom "Play Again" Container Card
                ZStack {
                    Image("card-play-again")
                        .resizable()
                        .aspectRatio(376.0 / 161.0, contentMode: .fit)
                        .frame(width: 320)

                    VStack(spacing: 12) {
                        Text("Want to explore again ?")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)

                        Button {
                            onPlayAgain()
                        } label: {
                            ZStack {
                                Image("btn-sort")
                                    .resizable()
                                    .aspectRatio(144.0 / 57.0, contentMode: .fit)
                                    .frame(width: 145)

                                Text("YES, PLAY AGAIN")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.black)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .offset(y: 16)
                }

                // Back to Menu Button
                Button {
                    onBackToMenu()
                } label: {
                    Text("BACK TO MAIN MENU")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    
    // MARK: - Logic

    private func select(_ answer: Answer) {
        selectedAnswer = answer

        withAnimation(
            .easeInOut(duration: 0.25)
        ) {
            answered = true
        }
    }
}
