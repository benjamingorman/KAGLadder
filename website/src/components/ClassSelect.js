import React, { Component } from 'react';
import './ClassSelect.css';
import RadioGroup from './RadioGroup';
import RadioButton from './RadioButton';
import ClassIcon from './ClassIcon';

class ClassSelect extends Component {
    render() {
        return (
            <div className="ClassSelect">
                <RadioGroup onChange={this.props.onChange} default="knight">
                    <RadioButton value="knight">
                        <ClassIcon kagClass="knight" />
                        Knight
                    </RadioButton>
                    <RadioButton value="archer">
                        <ClassIcon kagClass="archer" />
                        Archer
                    </RadioButton>
                    <RadioButton value="builder">
                        <ClassIcon kagClass="builder" />
                        Builder
                    </RadioButton>
                </RadioGroup>
            </div>
        );
    }
}
export default ClassSelect;
