type
    ComponentKind* = enum
        ckPwr,
        ckConnInput,
        ckConnOutput,
        ckConnPot,
        ckConnSwitch,
        ckRes,
        ckCap,
        ckCapP,
        ckInductor,
        ckDiode,
        ckDiodeZ,
        # ckTransistorN,
        # ckTransistorP,
        # add back once i figure out all the relevant parameters to solve for
        ckOpamp,
        ckOTA,
        ckASwitch
    ComponentVariant* = ref object
        connections*: seq[GraphNode] # each pin stored in order
        values*: seq[float]
        case kind*: ComponentKind:
            of ckPwr:
                infoPwrVoltage*: float
            of ckConnInput:
                infoInVoltage*: float
            of ckConnOutput:
                infoOutput*: float
            of ckConnPot:
                infoPotTurn*: float
            of ckConnSwitch:
                infoConnSPNTPos*: int
                infoConnSPNTStates*: int
            of ckRes:
                discard
            of ckCap:
                discard
            of ckCapP:
                discard
            of ckInductor:
                discard
            of ckDiode:
                discard
            of ckDiodeZ:
                discard
            # of ckTransistorN:
            #     infoTransistorModelN*: string
            # of ckTransistorP:
            #     infoTransistorModelP*: string
            of ckOpamp:
                infoOpampModel*: string
            of ckOTA:
                infoOTAModel*: string
            of ckASwitch:
                infoSPNTStates*: int
    SpringState* = ref object
        rest_length*: float
        current_length*: float
    GraphConnection* = object
        component*: ComponentVariant
        from_pin*: int
        to_pin*: int
        spring*: SpringState
    GraphNode* = ref object
        connections*: seq[GraphConnection]
        position*: array[2, int]
        velocity*: array[2, int]

proc componentConnections* (cv: ComponentVariant): int =
    case cv.kind:
        of ckPwr:
            return 1
        of ckConnInput:
            return 1
        of ckConnOutput:
            return 1
        of ckConnPot:
            return 3
        of ckConnSwitch:
            return 1 + cv.infoConnSPNTStates
        of ckRes:
            return 2
        of ckCap:
            return 2
        of ckCapP:
            return 2
        of ckInductor:
            return 2
        of ckDiode:
            return 2
        of ckDiodeZ:
            return 2
        # of ckTransistorN:
        #     return 3
        # of ckTransistorP:
        #     return 3
        of ckOpamp:
            return 3
        of ckOTA:
            return 5
        of ckASwitch:
            return 2 + cv.infoSPNTStates

proc componentValues* (kind: ComponentKind): int =
    case kind:
        of ckPwr:
            return 0
        of ckConnInput:
            return 0
        of ckConnOutput:
            return 0
        of ckConnPot:
            return 0
        of ckConnSwitch:
            return 0
        of ckRes:
            return 1
        of ckCap:
            return 1
        of ckCapP:
            return 1
        of ckInductor:
            return 1
        of ckDiode:
            return 0
        of ckDiodeZ:
            return 1
        # of ckTransistorN:
        #     return 3
        # of ckTransistorP:
        #     return 3
        of ckOpamp:
            return 0
        of ckOTA:
            return 0
        of ckASwitch:
            return 0

proc componentOrder* (x, y: ComponentVariant): int =
    cmp(x.kind, y.kind)
