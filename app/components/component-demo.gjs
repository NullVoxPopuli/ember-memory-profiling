import EC from '@ember/component';
import GC from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { run } from '@ember/runloop';

class Toggler extends GC {
  @tracked isShowing = false;
  toggle = () => this.isShowing = !this.isShowing;

  <template>
    <button {{on 'click' this.toggle}} data-label={{@label}}>{{@label}}</button>
    <br>
    {{#if this.isShowing}}
      {{yield}}
    {{/if}}
  </template>

}

const DATA = Array(20_000);

class EmberExample extends EC {
  <template><div data-ember>static content here</div></template>
}
class GlimmerExample extends GC {
  <template><div data-glimmer>static content here</div></template>
}
const TOExample = <template><div data-to>static content here</div></template>;

const Ember = <template>
  <Toggler @label="@ember/component">
    {{#each DATA as |_|}}
      <EmberExample />
    {{/each}}
  </Toggler>
</template>;

const Glimmer = <template>
  <Toggler @label="@glimmer/component">
    {{#each DATA as |_|}}
      <GlimmerExample />
    {{/each}}
  </Toggler>
</template>;

const TemplateOnly = <template>
  <Toggler @label="template-only">
    {{#each DATA as |_|}}
      <TOExample />
    {{/each}}
  </Toggler>
</template>;

class Automate extends GC {
  <template>
    <fieldset>
      <legend>
        Automation
      </legend>

      See console after running this.

      {{#if this.isRunning}}running...{{/if}}

      <button {{on 'click' this.run}} disabled={{this.isRunning}}>Run</button>
    </fieldset>

  </template>

  @tracked isRunning = false;

  run = async () => {
    this.isRunning = true;
    let attrMap = {
    '@ember/component': 'data-ember',
    '@glimmer/component': 'data-glimmer',
    'template-only': 'data-to',
    }

    for (let scenario of ['@ember/component', '@glimmer/component', 'template-only']) {
      console.group(scenario);
      console.log('Allowing time for GC...');
      await new Promise(resolve => setTimeout(resolve, 1000));
      for await (const count of measure(scenario)) {
        console.info(`(Confirmation) Rendered: ${count}`);
      }
      console.groupEnd(scenario);
    }
    this.isRunning = false;
  }
}

let attrMap = {
  '@ember/component': 'data-ember',
  '@glimmer/component': 'data-glimmer',
  'template-only': 'data-to',
}

/**
  * Getting more fine grained timing here is going to be hard, this is why we use very big numbers,
  * to try to lock up the main thread
  */
async function* measure(scenario) {
    let selector = attrMap[scenario];
    let button = document.querySelector(`[data-label="${scenario}"]`);

    console.log(`divs before: ${document.querySelectorAll('div').length}`);
    console.time('runtime');
    button.click();

    await Promise.resolve();
    let waitingForFinish = new Promise(resolve => {
      run('afterRender', async function () {
        await Promise.resolve();
        console.timeEnd('runtime');
        console.log(`divs after: ${document.querySelectorAll('div').length}`);
        let elements = document.querySelectorAll(`[${selector}]`);
        // close the demo
        button.click();
        let count = [...elements].length;

        resolve(count);
      });
    });

    yield waitingForFinish;
}

<template>
    <Automate />
    <Ember />
    <Glimmer />
    <TemplateOnly />
</template>
