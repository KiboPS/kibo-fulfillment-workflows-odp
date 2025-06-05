package com.kibocommerce.bpm.fulfillment

import org.kie.api.runtime.process.WorkflowProcessInstance
import kotlin.test.assertEquals

fun assertCurrentState(wpi: WorkflowProcessInstance, expectedState: String) {
    assertEquals(expectedState, wpi.getVariable("currentState"))
}
