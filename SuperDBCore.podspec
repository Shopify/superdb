Pod::Spec.new do |s|
  s.name         = "SuperDBCore"
  s.version      = "0.1"
  s.summary      = "Embeddable Core of the SuperDebugger."
  s.homepage     = "https://github.com/proger/superdb"

  s.license      = ""
  s.author       = {}

  s.source       = { :git => s.homepage + ".git", :branch => "pods" }

  
  s.subspec 'iOS' do |ios|
    ios.source_files = FileList[
                                'SuperDBCore/SuperDBCore/Array.m',
                                'SuperDBCore/SuperDBCore/ArrayRepBoolean.m',
                                'SuperDBCore/SuperDBCore/ArrayRepDouble.m',
                                'SuperDBCore/SuperDBCore/ArrayRepEmpty.m',
                                'SuperDBCore/SuperDBCore/ArrayRepFetchRequest.m',
                                'SuperDBCore/SuperDBCore/ArrayRepId.m',
                                'SuperDBCore/SuperDBCore/Block.m',
                                'SuperDBCore/SuperDBCore/BlockRep.m',
                                'SuperDBCore/SuperDBCore/BlockStackElem.m',
                                'SuperDBCore/SuperDBCore/CompiledCodeNode.m',
                                'SuperDBCore/SuperDBCore/FSArchiver.m',
                                'SuperDBCore/SuperDBCore/FSArray.m',
                                'SuperDBCore/SuperDBCore/FSArrayEnumerator.m',
                                'SuperDBCore/SuperDBCore/FSAssociation.m',
                                'SuperDBCore/SuperDBCore/FSBlock.m',
                                'SuperDBCore/SuperDBCore/FSBlockCompilationResult.m',
                                'SuperDBCore/SuperDBCore/FSBoolean.m',
                                'SuperDBCore/SuperDBCore/FSCNArray.m',
                                'SuperDBCore/SuperDBCore/FSCNAssignment.m',
                                'SuperDBCore/SuperDBCore/FSCNBase.m',
                                'SuperDBCore/SuperDBCore/FSCNBinaryMessage.m',
                                'SuperDBCore/SuperDBCore/FSCNBlock.m',
                                'SuperDBCore/SuperDBCore/FSCNCascade.m',
                                'SuperDBCore/SuperDBCore/FSCNCategory.m',
                                'SuperDBCore/SuperDBCore/FSCNClassDefinition.m',
                                'SuperDBCore/SuperDBCore/FSCNDictionary.m',
                                'SuperDBCore/SuperDBCore/FSCNIdentifier.m',
                                'SuperDBCore/SuperDBCore/FSCNKeywordMessage.m',
                                'SuperDBCore/SuperDBCore/FSCNMessage.m',
                                'SuperDBCore/SuperDBCore/FSCNMethod.m',
                                'SuperDBCore/SuperDBCore/FSCNPrecomputedObject.m',
                                'SuperDBCore/SuperDBCore/FSCNReturn.m',
                                'SuperDBCore/SuperDBCore/FSCNStatementList.m',
                                'SuperDBCore/SuperDBCore/FSCNSuper.m',
                                'SuperDBCore/SuperDBCore/FSCNUnaryMessage.m',
                                'SuperDBCore/SuperDBCore/FSClassDefinition.m',
                                'SuperDBCore/SuperDBCore/FSCommandHistory.m',
                                'SuperDBCore/SuperDBCore/FSCompilationResult.m',
                                'SuperDBCore/SuperDBCore/FSCompiler.m',
                                'SuperDBCore/SuperDBCore/FSConstantsInitialization.m',
                                'SuperDBCore/SuperDBCore/FSError.m',
                                'SuperDBCore/SuperDBCore/FSExecEngine.m',
                                'SuperDBCore/SuperDBCore/FSExecutor.m',
                                'SuperDBCore/SuperDBCore/FSGenericPointer.m',
                                'SuperDBCore/SuperDBCore/FSGlobalScope.m',
                                'SuperDBCore/SuperDBCore/FSIdentifierFormatter.m',
                                'SuperDBCore/SuperDBCore/FSInterpreter.m',
                                'SuperDBCore/SuperDBCore/FSInterpreterResult.m',
                                'SuperDBCore/SuperDBCore/FSKeyedArchiver.m',
                                'SuperDBCore/SuperDBCore/FSKeyedUnarchiver.m',
                                'SuperDBCore/SuperDBCore/FSMethod-iOS.m',
                                'SuperDBCore/SuperDBCore/FSMiscTools.m',
                                'SuperDBCore/SuperDBCore/FSMsgContext.m',
                                'SuperDBCore/SuperDBCore/FSNSArray.m',
                                'SuperDBCore/SuperDBCore/FSNSAttributedString.m',
                                'SuperDBCore/SuperDBCore/FSNSDate.m',
                                'SuperDBCore/SuperDBCore/FSNSDictionary.m',
                                'SuperDBCore/SuperDBCore/FSNSFileHandle.m',
                                'SuperDBCore/SuperDBCore/FSNSManagedObjectContext.m',
                                'SuperDBCore/SuperDBCore/FSNSMutableArray.m',
                                'SuperDBCore/SuperDBCore/FSNSMutableDictionary.m',
                                'SuperDBCore/SuperDBCore/FSNSMutableString.m',
                                'SuperDBCore/SuperDBCore/FSNSNumber.m',
                                'SuperDBCore/SuperDBCore/FSNSObject.m',
                                'SuperDBCore/SuperDBCore/FSNSProxy.m',
                                'SuperDBCore/SuperDBCore/FSNSSet.m',
                                'SuperDBCore/SuperDBCore/FSNSString.m',
                                'SuperDBCore/SuperDBCore/FSNSValue-iOS.m',
                                'SuperDBCore/SuperDBCore/FSNamedNumber.m',
                                'SuperDBCore/SuperDBCore/FSNewlyAllocatedObjectHolder.m',
                                'SuperDBCore/SuperDBCore/FSNumber.m',
                                'SuperDBCore/SuperDBCore/FSObjectFormatter.m',
                                'SuperDBCore/SuperDBCore/FSObjectPointer.m',
                                'SuperDBCore/SuperDBCore/FSPattern.m',
                                'SuperDBCore/SuperDBCore/FSPointer.m',
                                'SuperDBCore/SuperDBCore/FSReplacementForCoderForClass.m',
                                'SuperDBCore/SuperDBCore/FSReplacementForCoderForNilInArray.m',
                                'SuperDBCore/SuperDBCore/FSReturnSignal.m',
                                'SuperDBCore/SuperDBCore/FSSymbolTable.m',
                                'SuperDBCore/SuperDBCore/FSSystem.m',
                                'SuperDBCore/SuperDBCore/FSTranscript.m',
                                'SuperDBCore/SuperDBCore/FSUnarchiver.m',
                                'SuperDBCore/SuperDBCore/FSVoid.m',
                                'SuperDBCore/SuperDBCore/FScriptFunctions.m',
                                'SuperDBCore/SuperDBCore/Geometry.m',
                                'SuperDBCore/SuperDBCore/MessagePatternCodeNode.m',
                                'SuperDBCore/SuperDBCore/Number.m',
                                'SuperDBCore/SuperDBCore/Pointer.m',
                                'SuperDBCore/SuperDBCore/Space.m',
                                'SuperDBCore/SuperDBCore/ffi-iphone.c',
                                'SuperDBCore/SuperDBCore/ffi-iphonesimulator.c',
                                'SuperDBCore/SuperDBCore/iOS-glue.m',
                                'SuperDBCore/SuperDBCore/iphone-sysv.S',
                                'SuperDBCore/SuperDBCore/iphonesimulator-darwin.S',
                                'SuperDBCore/SuperDBCore/prep_cif.c',
                                'SuperDBCore/SuperDBCore/raw_api.c',
                                'SuperDBCore/SuperDBCore/types.c',
                                
#                                'SuperDBCore/SuperDBCore/FScriptDict.dic',

                                'SuperDBCore/SuperDBCore/*.h',
                               ]
    ios.requires_arc = false

    ios.compiler_flags = ["-include 'iOS-Glue.h'"]

    ios.subspec 'ARC' do |arc|
      arc.source_files = FileList[
                                  'SuperDBCore/SuperDBCore/GCDAsyncSocket.m',
                                  'SuperDBCore/SuperDBCore/SuperInterpreter.m',
                                  'SuperDBCore/SuperDBCore/SuperInterpreterClient.m',
                                  'SuperDBCore/SuperDBCore/SuperInterpreterObjectBrowser.m',
                                  'SuperDBCore/SuperDBCore/SuperInterpreterService.m',
                                  'SuperDBCore/SuperDBCore/SuperJSTP.m',
                                  'SuperDBCore/SuperDBCore/SuperNetworkMessage.m',
                                  'SuperDBCore/SuperDBCore/SuperServicesBrowser.m',
                                 ]
      arc.requires_arc = true
    end
  end

  s.subspec 'OSXClient' do |osx|
     osx.source_files = FileList[
                                 'SuperDBCore/SuperDBCore/SuperJSTP.m',
                                 'SuperDBCore/SuperDBCore/SuperServicesBrowser.m',
                                 'SuperDBCore/SuperDBCore/GCDAsyncSocket.m',
                                 'SuperDBCore/SuperDBCore/SuperInterpreterClient.m',
                                 'SuperDBCore/SuperDBCore/SuperNetworkMessage.m',

                                 'SuperDBCore/SuperDBCore/*.h',
                                ]
    osx.requires_arc = true
  end

end
