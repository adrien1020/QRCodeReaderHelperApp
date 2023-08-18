//
//  ContentView.swift
//  QRCodeReaderHelper
//
//  Created by Adrien Surugue on 18/08/2023.
//

import AVFoundation
import SwiftUI

struct ContentView: View {
    
    @State var showBarCodeReader = false
    
    var body: some View {
        Button(action: {
            showBarCodeReader.toggle()
        }, label: {
            Image(systemName: "qrcode.viewfinder")
                .font(.largeTitle)
        })
        .fullScreenCover(isPresented: $showBarCodeReader){
            BarCodeReaderView(showBarCodeReader: $showBarCodeReader)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct BarCodeReaderView: View {
   
    @Binding var showBarCodeReader: Bool
    
    @State private var showAlert = false
    @State private var barCode = ""
    @State private var captureSession = AVCaptureSession()
    @State private var showCode = false
    
    init(showBarCodeReader:Binding<Bool>) {
        self._showBarCodeReader = showBarCodeReader
    }
    
    var body: some View {
        NavigationView{
                BarCodePreview(stringCode: { barCode in
                    self.barCode = barCode
                    self.showCode = true
                 
                }, showAlert: $showAlert, captureSession: $captureSession)
                
                .alert(barCode, isPresented: $showCode){
                    Button(action: {
                        DispatchQueue.global(qos: .background).async {
                            captureSession.startRunning()
                        }
                    }, label: {
                        Text("Retry")
                    })
                }
                .alert("Your device does not support scanning a code from an item. Please use a device with a camera.", isPresented:$showAlert){
                    Button("OK", action: {
                        self.showBarCodeReader = false
                    }
                    )}
            .navigationBarItems(leading: Button(action: {
                
                self.showBarCodeReader = false
            }, label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white)
                    .padding(6)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
