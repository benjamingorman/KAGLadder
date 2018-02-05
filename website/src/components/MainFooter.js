import React, { Component } from 'react';
import {Link} from 'react-router-dom';
import './MainFooter.css';
//import Mailto from 'react-mailto';

//<Mailto email="8076bgorman@gmail.com" obfuscate={true}><span>Contact</span></Mailto>
class MainFooter extends Component {
    render() {
        return (
            <div className="MainFooter">
                <div className="_content">
                    <div>
                        <Link to="/about"><span>About</span></Link>
                        <a href="mailto:8076bgorman@gmail.com?Subject=KAGLadder"><span>Contact</span></a>
                        <a href="https://api.kagladder.com"><span>API</span></a>
                        <a href="https://github.com/benjamingorman/KAGELO"><span>GitHub</span></a>
                    </div>
                    <div>
                        <span className="_copyright">Copyright (c) 2018 Benjamin Gorman All Rights Reserved.</span>
                    </div>
                </div>
            </div>
        );
    }
}
export default MainFooter;
