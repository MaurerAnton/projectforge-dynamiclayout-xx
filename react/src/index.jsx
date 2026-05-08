import React from 'react';
import DynamicLayoutContext from './context';
import renderLayout, { registerComponent } from './DynamicRenderer';
import DynamicActionGroup from './action/DynamicActionGroup';

export { DynamicLayoutContext, renderLayout, registerComponent };

export { default as DynamicGroup } from './components/DynamicGroup';
export { default as DynamicFieldset } from './components/DynamicFieldset';
export { default as DynamicLabel } from './components/DynamicLabel';
export { default as DynamicButton } from './components/DynamicButton';
export { default as DynamicAlert } from './components/DynamicAlert';
export { default as DynamicSpacer } from './components/DynamicSpacer';
export { default as DynamicBadge } from './components/DynamicBadge';
export { default as DynamicBadgeList } from './components/DynamicBadgeList';
export { default as DynamicList } from './components/DynamicList';
export { default as DynamicInputResolver } from './components/input/DynamicInputResolver';
export { default as DynamicInput } from './components/input/DynamicInput';
export { default as DynamicCheckbox } from './components/input/DynamicCheckbox';
export { default as DynamicTextArea } from './components/input/DynamicTextArea';
export { default as DynamicRadioButton } from './components/input/DynamicRadioButton';
export { default as DynamicReadonlyField } from './components/input/DynamicReadonlyField';

export function DynamicLayout({
    children,
    ui,
    callAction = () => {},
    data = {},
    options = {},
    setData = () => {},
    setVariables = () => {},
    validationErrors = [],
    variables = {},
    ...props
}) {
    const {
        actions,
        layout,
        layoutBelowActions,
        title,
        historyBackButton,
    } = ui;

    const contextValue = React.useMemo(() => ({
        ui,
        options,
        renderLayout,
        callAction,
        data,
        setData,
        setVariables,
        validationErrors,
        variables,
        ...props,
    }), [
        ui, options, callAction, data, setData, setVariables,
        validationErrors, variables,
    ]);

    return (
        <DynamicLayoutContext.Provider value={contextValue}>
            {children}
            {renderLayout(layout)}
            {actions && <DynamicActionGroup actions={actions} />}
            {renderLayout(layoutBelowActions)}
        </DynamicLayoutContext.Provider>
    );
}
