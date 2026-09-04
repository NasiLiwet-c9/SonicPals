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

    private let sfx = SfxSvc.shared

    enum Answer {
        case ultrasonic
        case flashlight
    }

    private let question =
        "What did you use to find the mangoes last night?"

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                Color.black
                    .opacity(0.15)
                    .ignoresSafeArea()

                if answered {
                    resultView(size)
                } else {
                    questionView(size)
                }
            }
            .frame(
                width: size.width,
                height: size.height
            )
        }
        .ignoresSafeArea()
        .transition(
            .scale(scale: 0.72)
            .combined(with: .opacity)
        )
        .onAppear {
            sfx.popup()
        }
    }

    private func questionView(
        _ size: CGSize
    ) -> some View {
        ZStack {
            Image("quiz-card-bg")
                .resizable()
                .aspectRatio(
                    379.0 / 439.0,
                    contentMode: .fit
                )
                .frame(
                    width: UICfg.v(
                        UICfg.Quiz.cardW,
                        size
                    )
                )

            VStack(
                spacing: UICfg.v(
                    UICfg.Quiz.qGap,
                    size
                )
            ) {
                Text(question)
                    .font(
                        .system(
                            size: UICfg.v(
                                UICfg.Quiz.qTxt,
                                size
                            ),
                            weight: .heavy
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                    .frame(
                        width: UICfg.v(
                            UICfg.Quiz.qW,
                            size
                        )
                    )

                VStack(
                    spacing: UICfg.v(
                        UICfg.Quiz.ansGap,
                        size
                    )
                ) {
                    answerButton(
                        title: "A. ULTRASONIC",
                        answer: .ultrasonic,
                        size: size
                    )

                    answerButton(
                        title: "B. FLASHLIGHT",
                        answer: .flashlight,
                        size: size
                    )
                }
            }
            .frame(
                width: UICfg.v(
                    UICfg.Quiz.cardW,
                    size
                ),
                height: UICfg.v(
                    UICfg.Quiz.cardH,
                    size
                ),
                alignment: .center
            )
        }
    }

    private func answerButton(
        title: String,
        answer: Answer,
        size: CGSize
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
                    .frame(
                        width: UICfg.v(
                            UICfg.Quiz.ansW,
                            size
                        )
                    )

                Text(title)
                    .font(
                        .system(
                            size: UICfg.v(
                                UICfg.Quiz.ansTxt,
                                size
                            ),
                            weight: .heavy
                        )
                    )
                    .foregroundStyle(.black)
            }
        }
        .buttonStyle(.plain)
    }

    private var isCorrect: Bool {
        selectedAnswer == .ultrasonic
    }

    private func resultView(
        _ size: CGSize
    ) -> some View {
        VStack(
            spacing: UICfg.v(
                UICfg.Quiz.gap,
                size
            )
        ) {
            resultCard(size)

            replayCard(size)

            Button {
                sfx.tap()
                onBackToMenu()
            } label: {
                Text("BACK TO MAIN MENU")
                    .font(
                        .system(
                            size: UICfg.v(
                                UICfg.Quiz.backTxt,
                                size
                            ),
                            weight: .heavy
                        )
                    )
                    .foregroundStyle(
                        Color(
                            red: 0.9,
                            green: 0.3,
                            blue: 0.3
                        )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func resultCard(
        _ size: CGSize
    ) -> some View {
        ZStack(alignment: .top) {
            Image(
                isCorrect
                    ? "correct-quiz-card"
                    : "incorrect-quiz-card"
            )
            .resizable()
            .aspectRatio(
                contentMode: .fit
            )
            .frame(
                width: UICfg.v(
                    UICfg.Quiz.resW,
                    size
                )
            )

            VStack(
                spacing: UICfg.v(9, size)
            ) {
                if isCorrect {
                    Text("A. ULTRASONIC")
                        .font(
                            .system(
                                size: UICfg.v(
                                    UICfg.Quiz.resTitle,
                                    size
                                ),
                                weight: .heavy
                            )
                        )
                        .foregroundStyle(
                            Color(
                                red: 0.15,
                                green: 0.2,
                                blue: 0.45
                            )
                        )

                    Text(
                        "You are super smart! You used your superpower perfectly."
                    )
                    .font(
                        .system(
                            size: UICfg.v(
                                UICfg.Quiz.resTxt,
                                size
                            ),
                            weight: .bold
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                    .frame(
                        width: UICfg.v(
                            UICfg.Quiz.resTxtW,
                            size
                        )
                    )
                    .lineSpacing(
                        UICfg.v(3, size)
                    )
                } else {
                    Text(
                        "That's not it. Remember the bouncy sound we used? Try again!"
                    )
                    .font(
                        .system(
                            size: UICfg.v(
                                UICfg.Quiz.resTxt,
                                size
                            ),
                            weight: .bold
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                    .frame(
                        width: UICfg.v(
                            UICfg.Quiz.resTxtW,
                            size
                        )
                    )
                    .lineSpacing(
                        UICfg.v(3, size)
                    )
                }
            }
            .padding(
                .top,
                UICfg.v(
                    UICfg.Quiz.resTop,
                    size
                )
            )
        }
    }

    private func replayCard(
        _ size: CGSize
    ) -> some View {
        ZStack {
            Image("card-play-again")
                .resizable()
                .aspectRatio(
                    376.0 / 161.0,
                    contentMode: .fit
                )
                .frame(
                    width: UICfg.v(
                        UICfg.Quiz.againW,
                        size
                    )
                )

            VStack(
                spacing: UICfg.v(12, size)
            ) {
                Text("Want to explore again ?")
                    .font(
                        .system(
                            size: UICfg.v(
                                UICfg.Quiz.againTxt,
                                size
                            ),
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.black)

                Button {
                    sfx.tap()
                    onPlayAgain()
                } label: {
                    ZStack {
                        Image("btn-sort")
                            .resizable()
                            .aspectRatio(
                                144.0 / 57.0,
                                contentMode: .fit
                            )
                            .frame(
                                width: UICfg.v(
                                    UICfg.Quiz.againBtnW,
                                    size
                                )
                            )

                        Text("YES, PLAY AGAIN")
                            .font(
                                .system(
                                    size: UICfg.v(
                                        UICfg.Quiz.againBtnTxt,
                                        size
                                    ),
                                    weight: .heavy
                                )
                            )
                            .foregroundStyle(.black)
                    }
                }
                .buttonStyle(.plain)
            }
            .offset(
                y: UICfg.y(
                    16,
                    size
                )
            )
        }
    }

    private func select(
        _ answer: Answer
    ) {
        sfx.tap()

        selectedAnswer = answer

        if answer == .ultrasonic {
            sfx.correct()
        } else {
            sfx.incorrect()
        }

        withAnimation(
            .easeInOut(duration: 0.25)
        ) {
            answered = true
        }
    }
}

#Preview("Quiz") {
    QuestionCardView(
        onPlayAgain: {},
        onBackToMenu: {}
    )
}
