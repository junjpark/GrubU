//
//  ImagePicker.swift
//
//  UIKit image picker bridged for SwiftUI (proof photos).
//
//  Created by user287016 on 4/7/26.
//


import SwiftUIimport UIKitstruct ImagePicker: UIViewControllerRepresentable {    @Binding var image: UIImage?    @Environment(\.presentationMode) private var presentationMode    func makeUIViewController(context: Context) -> UIImagePickerController {        let picker = UIImagePickerController()        picker.delegate = context.coordinator        // Change to .camera if you want to force them to take a live photo        picker.sourceType = .photoLibrary         return picker    }    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}    func makeCoordinator() -> Coordinator {        Coordinator(self)    }    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {        let parent: ImagePicker        init(_ parent: ImagePicker) {            self.parent = parent        }        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {            if let uiImage = info[.originalImage] as? UIImage {                parent.image = uiImage            }            parent.presentationMode.wrappedValue.dismiss()        }    }}