import AppKit
import SwiftUI

struct NativeStepperField: NSViewRepresentable {
    @Binding var value: Int
    let minValue: Int
    let maxValue: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value)
    }

    func makeNSView(context: Context) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 10
        stack.alignment = .centerY

        let textField = NSTextField(string: "\(value)")
        textField.isEditable = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.font = .systemFont(ofSize: 14, weight: .semibold)
        textField.alignment = .left
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.widthAnchor.constraint(equalToConstant: 36).isActive = true

        let stepper = NSStepper()
        stepper.minValue = Double(minValue)
        stepper.maxValue = Double(maxValue)
        stepper.increment = 1
        stepper.integerValue = value
        stepper.target = context.coordinator
        stepper.action = #selector(Coordinator.didChange(_:))

        context.coordinator.textField = textField
        context.coordinator.stepper = stepper

        stack.addArrangedSubview(textField)
        stack.addArrangedSubview(stepper)
        return stack
    }

    func updateNSView(_ nsView: NSStackView, context: Context) {
        context.coordinator.textField?.stringValue = "\(value)"
        context.coordinator.stepper?.integerValue = value
    }

    final class Coordinator: NSObject {
        @Binding var value: Int
        weak var textField: NSTextField?
        weak var stepper: NSStepper?

        init(value: Binding<Int>) {
            _value = value
        }

        @objc func didChange(_ sender: NSStepper) {
            value = sender.integerValue
            textField?.stringValue = "\(value)"
        }
    }
}
